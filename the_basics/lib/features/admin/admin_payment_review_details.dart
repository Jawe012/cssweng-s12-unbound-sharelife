import 'package:flutter/material.dart';
import 'package:the_basics/core/widgets/side_menu.dart';
import 'package:the_basics/core/widgets/top_navbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_basics/core/utils/export_service.dart';
import 'package:the_basics/core/utils/themes.dart';
// removed email/edge-function usage — notifications are driven by the app

class AdminPaymentReviewDetails extends StatefulWidget {
  const AdminPaymentReviewDetails({super.key});

  @override
  State<AdminPaymentReviewDetails> createState() => _AdminPaymentReviewDetailsState();
}

class _AdminPaymentReviewDetailsState extends State<AdminPaymentReviewDetails> {
  // Payment details
  int paymentId = 0;
  int loanId = 0;
  String memberName = '';
  double amount = 0.0;
  String paymentType = '';
  String paymentDate = '';
  String status = '';
  int installmentNumber = 0;
  
  // Payment-type specific fields
  String? gcashReference;
  String? gcashScreenshotPath;
  String? bankName;
  String? bankDepositDate;
  String? staffName;
  
  bool _isLoading = true;
  bool _isProcessing = false;
  String? decision; // 'Validated' or 'Invalidated'
  final TextEditingController remarksController = TextEditingController();

  // for spacing
  double titleSpacing = 18;
  double textSpacing = 12;
  double dataSpacing = 100;

  // font sizes
  double titleFont = 20;
  double contentFont = 16;

  String formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      if (timestamp is DateTime) {
        final d = timestamp;
        return "${d.month}/${d.day}/${d.year}";
      } else {
        final d = DateTime.parse(timestamp.toString());
        return "${d.month}/${d.day}/${d.year}";
      }
    } catch (_) {
      return 'N/A';
    }
  }

  Future<void> fetchPaymentDetails(int id) async {
    setState(() => _isLoading = true);
    
    try {
      // Fetch payment details with related loan and member info
      final response = await Supabase.instance.client
          .from('payments')
          .select('''
            payment_id,
            approved_loan_id,
            amount,
            payment_type,
            payment_date,
            status,
            installment_number,
            gcash_reference,
            gcash_screenshot_path,
            bank_name,
            bank_deposit_date,
            staff_id,
            created_at,
            approved_loans!inner(
              member_first_name,
              member_last_name,
              member_id,
              loan_amount
            )
          ''')
          .eq('payment_id', id)
          .maybeSingle();

      if (response != null) {
        // Fetch staff name if staff_id exists
        String? fetchedStaffName;
          if (response['staff_id'] != null) {
          try {
            final staffResp = await Supabase.instance.client
                .from('staff')
                .select('first_name, last_name')
                .eq('id', response['staff_id'])
                .maybeSingle();
            
            if (staffResp != null) {
              fetchedStaffName = "${staffResp['first_name']} ${staffResp['last_name']}";
            }
          } catch (e) {
            debugPrint('Error fetching staff: $e');
          }
        }

        setState(() {
          paymentId = response['payment_id'] ?? 0;
          loanId = response['approved_loan_id'] ?? 0;
          amount = (response['amount'] ?? 0).toDouble();
          paymentType = response['payment_type'] ?? '';
          paymentDate = formatDate(response['payment_date'] ?? response['created_at']);
          status = response['status'] ?? '';
          installmentNumber = response['installment_number'] ?? 0;
          
          // Member info from nested object
          if (response['approved_loans'] != null) {
            memberName = "${response['approved_loans']['member_first_name']} ${response['approved_loans']['member_last_name']}";
          }
          
          // Payment-type specific fields
          gcashReference = response['gcash_reference'];
          gcashScreenshotPath = response['gcash_screenshot_path'];
          bankName = response['bank_name'];
          bankDepositDate = formatDate(response['bank_deposit_date']);
          staffName = fetchedStaffName;
          
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment record not found'))
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading payment details: $e'))
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      int? id;

      if (args is int) {
        id = args;
      } else if (args is Map) {
        id = args['payment_id'] ?? args['id'];
      }

      if (id != null) {
        fetchPaymentDetails(id);
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No payment ID provided')),
        );
      }
    });
  }

  Future<void> updatePaymentStatus(String newStatus) async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      // Get current staff ID for reviewed_by if available
      int? reviewerId;
      try {
        final currentUser = Supabase.instance.client.auth.currentUser;
        final userEmail = currentUser?.email;
        if (userEmail != null) {
          final staffRecord = await Supabase.instance.client
              .from('staff')
              .select('id')
              .eq('email_address', userEmail)
              .maybeSingle();
          if (staffRecord != null) reviewerId = staffRecord['id'] as int?;
        }
      } catch (e) {
        debugPrint('Failed to resolve reviewer id: $e');
      }

      // Prepare update payload. Include remarks/date_reviewed/reviewed_by if available
      final Map<String, dynamic> paymentUpdates = {
        'status': newStatus,
      };
      if (remarksController.text.isNotEmpty) paymentUpdates['remarks'] = remarksController.text;
      paymentUpdates['date_reviewed'] = DateTime.now().toIso8601String();
      if (reviewerId != null) paymentUpdates['reviewed_by'] = reviewerId;

      // Update payment status and metadata
      await Supabase.instance.client
          .from('payments')
          .update(paymentUpdates)
          .eq('payment_id', paymentId);

      if (!mounted) return;

      // If payment was validated, apply it to the approved loan balance
      if (newStatus == 'Validated') {
        try {
          // Fetch the current loan record
          final loanResp = await Supabase.instance.client
              .from('approved_loans')
              .select('application_id, loan_amount, amount_paid, outstanding_balance, member_id')
              .eq('application_id', loanId)
              .maybeSingle();

          if (loanResp != null) {
            // Parse numeric values safely
            final currentPaid = (loanResp['amount_paid'] ?? 0) as num;
            final loanAmount = (loanResp['loan_amount'] ?? 0) as num;
            final paymentAmount = amount as num;
            final newAmountPaid = currentPaid + paymentAmount;
            final newOutstanding = (loanAmount - newAmountPaid).toDouble();

            final Map<String, dynamic> updates = {
              'amount_paid': newAmountPaid,
              'outstanding_balance': newOutstanding,
            };

            // If fully paid or negative outstanding, mark as Paid
            if (newOutstanding <= 0) {
              updates['status'] = 'Paid';
            }

            await Supabase.instance.client
                .from('approved_loans')
                .update(updates)
                .eq('application_id', loanId);

            // If loan now Paid, clear member.has_loan
            if (newOutstanding <= 0) {
              final memberId = loanResp['member_id'];
              if (memberId != null) {
                await Supabase.instance.client
                    .from('members')
                    .update({'has_loan': false})
                    .eq('id', memberId);
              }
            }
          }
        } catch (e) {
          debugPrint('Error applying validated payment to loan: $e');
        }

        // Notifications will be surfaced by the app's notification system
        // (the NotificationsListPage reads the payments/approved_loans tables
        // and will show the appropriate 'payment_valid' notification when
        // the payment record status is set to 'Validated').
      }

      // Show success dialog (guard context after async work)
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Success'),
          content: Text('Payment has been ${newStatus == "Validated" ? "validated" : "invalidated"}.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                if (mounted) Navigator.of(context).pop(); // Return to list
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating payment status: $e'))
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    remarksController.dispose();
    super.dispose();
  }

  void _showConfirmationDialog(String action, String newStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm $action'),
        content: Text('Are you sure you want to $action this payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close confirmation dialog
              updatePaymentStatus(newStatus);
            },
            style: TextButton.styleFrom(
              foregroundColor: action == 'Validate' ? AppThemes.confirmButton : AppThemes.rejectButton,
            ),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  // Notifications are handled by the app's notification system; no edge call.

  Widget paymentInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Payment Information", 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: titleFont)),
        SizedBox(height: titleSpacing),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Payment ID: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Loan ID: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Member Name: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Amount: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Installment #: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Payment Type: ", style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text("Date: ", style: TextStyle(fontSize: contentFont)),
              ],
            ),
            SizedBox(width: dataSpacing),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$paymentId', style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text('$loanId', style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text(memberName, style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text(ExportService.safeCurrency(amount), style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text('$installmentNumber', style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text(paymentType, style: TextStyle(fontSize: contentFont)),
                SizedBox(height: textSpacing),
                Text(paymentDate, style: TextStyle(fontSize: contentFont)),
              ],
            ),
          ],
        )
      ],
    );
  }

  Widget paymentTypeSpecificInfo() {
    if (paymentType == 'Gcash') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24),
          Text("GCash Details", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: titleFont)),
          SizedBox(height: titleSpacing),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Reference Number: ", style: TextStyle(fontSize: contentFont)),
                  SizedBox(height: textSpacing),
                  Text("Screenshot: ", style: TextStyle(fontSize: contentFont)),
                ],
              ),
              SizedBox(width: dataSpacing),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(gcashReference ?? 'N/A', style: TextStyle(fontSize: contentFont)),
                  SizedBox(height: textSpacing),
                  if (gcashScreenshotPath != null)
                    InkWell(
                      onTap: () async {
                        try {
                          // Get public URL from storage
                          final publicUrl = Supabase.instance.client.storage
                              .from('payment_receipts')
                              .getPublicUrl(gcashScreenshotPath!);
                          
                          // Show image in dialog
                          if (mounted) {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppBar(
                                      title: const Text('GCash Screenshot'),
                                      automaticallyImplyLeading: false,
                                      actions: [
                                        IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () => Navigator.pop(context),
                                        ),
                                      ],
                                    ),
                                    Expanded(
                                      child: InteractiveViewer(
                                        child: Image.network(
                                          publicUrl,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.error, size: 48, color: Colors.red),
                                                  SizedBox(height: 16),
                                                  Text('Failed to load image'),
                                                  SizedBox(height: 8),
                                                  Text(publicUrl, style: TextStyle(fontSize: 12)),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error loading screenshot: $e')),
                            );
                          }
                        }
                      },
                      child: Text('View Screenshot', 
                          style: TextStyle(fontSize: contentFont, color: Colors.blue, decoration: TextDecoration.underline)),
                    )
                  else
                    Text('No screenshot uploaded', style: TextStyle(fontSize: contentFont, color: Colors.grey)),
                ],
              ),
            ],
          )
        ],
      );
    } else if (paymentType == 'Bank_Transfer' || paymentType == 'Bank Transfer') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24),
          Text("Bank Transfer Details", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: titleFont)),
          SizedBox(height: titleSpacing),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Bank Name: ", style: TextStyle(fontSize: contentFont)),
                  SizedBox(height: textSpacing),
                  Text("Deposit Date: ", style: TextStyle(fontSize: contentFont)),
                ],
              ),
              SizedBox(width: dataSpacing),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bankName ?? 'N/A', style: TextStyle(fontSize: contentFont)),
                  SizedBox(height: textSpacing),
                  Text(bankDepositDate ?? 'N/A', style: TextStyle(fontSize: contentFont)),
                ],
              ),
            ],
          )
        ],
      );
    } else if (paymentType == 'Cash') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24),
          Text("Cash Payment Details", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: titleFont)),
          SizedBox(height: titleSpacing),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Received by Staff: ", style: TextStyle(fontSize: contentFont)),
                ],
              ),
              SizedBox(width: dataSpacing),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(staffName ?? 'N/A', style: TextStyle(fontSize: contentFont)),
                ],
              ),
            ],
          )
        ],
      );
    }
    return SizedBox.shrink();
  }

  Widget actionButtons() {
    // Decision section mirrors Loan Review details: dropdown + remarks + confirm
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Text("Decision",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: titleFont,
            )),
        SizedBox(height: titleSpacing),
        Row(
          children: [
            Text("Decision:  "),
            SizedBox(width: titleSpacing),
            DropdownButton<String>(
              value: decision,
              hint: const Text('Choose'),
              items: [
                const DropdownMenuItem(value: 'Validated', child: Text('Validate')),
                const DropdownMenuItem(value: 'Invalidated', child: Text('Invalidate')),
              ],
              onChanged: (value) {
                setState(() {
                  decision = value;
                });
              },
            ),
          ],
        ),
        SizedBox(height: 12),
        TextField(
          controller: remarksController,
          decoration: InputDecoration(
            labelText: "Remarks (optional)",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
        SizedBox(height: 10),
        Text(
          "Member will be notified of the payment status update.",
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: (decision == null || _isProcessing) ? null : () => _showConfirmationDialog(decision == 'Validated' ? 'Validate' : 'Invalidate', decision!),
          style: ElevatedButton.styleFrom(
            backgroundColor: decision == 'Validated'
                ? Colors.green
                : (decision == 'Invalidated' ? Colors.red : Colors.grey),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          ),
          child: _isProcessing
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text(
                  "Confirm",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
        ),
        SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
    decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage("assets/imgs/bg_in.png"),
        fit: BoxFit.cover,
      ),
    ),
    child: Column(
        children: [
          const TopNavBar(splash: "Admin"),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SideMenu(role: "Admin"),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: _isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 900),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Back button and title
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.arrow_back),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Payment Review Details",
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: AppThemes.pageTitle
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.only(left: 48),
                                  child: Text(
                                    "Review the payment details and validate or invalidate the submission.",
                                    style: TextStyle(color: AppThemes.pageSubtitle, fontSize: 14),
                                  ),
                                ),
                                SizedBox(height: 32),
                                
                                // Payment details in a card
                                Container(
                                  padding: EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      paymentInfo(),
                                      paymentTypeSpecificInfo(),
                                      actionButtons(),
                                    ],
                                  ),
                                ),
                                
                                SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
    );
  }
}