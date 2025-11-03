import 'package:flutter/material.dart';
import 'package:the_basics/widgets/top_navbar.dart';
import 'package:the_basics/widgets/side_menu.dart';
import 'package:the_basics/widgets/input_fields.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemberPaymentForm extends StatefulWidget {
  const MemberPaymentForm({super.key});

  @override
  State<MemberPaymentForm> createState() => _MemberPaymentFormState();
}

class _MemberPaymentFormState extends State<MemberPaymentForm> {
  
  // Payment Information
  String? selectedPaymentMethod;
  final TextEditingController amountPaidController = TextEditingController();
  final TextEditingController paymentDateController = TextEditingController();

  // Payment Information
  final TextEditingController staffController = TextEditingController();
  final TextEditingController refNoController = TextEditingController();
  final TextEditingController receiptController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();
    
  // File upload
  final ImagePicker _picker = ImagePicker();
  XFile? proofOfPaymentFile;
  
  bool _isSubmitting = false;


  Widget buttonsRow() {
    return Row(
      children: [
        Spacer(),
        SizedBox(
          height: 28,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download,
                color: Colors.white),
            label: const Text(
              "Download",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              minimumSize: const Size(100, 28),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
      ]
    );
  }

  Widget paymentInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Payment Information",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),

        // Payment Method Dropdown
        SizedBox(
          width: 250,
          child: DropdownNonInputField(
            label: "Payment Method", 
            value: selectedPaymentMethod, 
            items: [
              "Cash",
              "Gcash",
              "Bank Transfer",
            ],
            onChanged: (value) {
              setState(() {
                selectedPaymentMethod = value;
              });
            },
          ),
        ),

        // Payment Fields
        SizedBox(height: 16),
        ...paymentMethodSpecificFields(selectedPaymentMethod ?? ""),
      ],
    );
  }

  List<Widget> paymentMethodSpecificFields(String method) {
    switch (method) {
      case "Cash":
        return [
          Row(
            children: [
              Expanded(
                child: NumberInputField(
                  label: "Amount Paid",
                  controller: amountPaidController,
                  hint: "₱0"
                ),
              ),              
              SizedBox(width: 16),

              Expanded(
                child: DateInputField(
                  label: "Date of Payment",
                  controller: paymentDateController,
                ),
              ),
              SizedBox(width: 16),

              Expanded(
                child: TextInputField(
                  label: "Staff Handling Payment",
                  controller: staffController,
                  hint: "e.g. John Doe",
                ),
              ),
            ],
          ),
        ];



      case "Gcash":
        return [
          Row(
            children: [
              Expanded(
                child: NumberInputField(
                  label: "Amount Paid",
                  controller: amountPaidController,
                  hint: "₱0"
                ),
              ),              
              SizedBox(width: 16),

              Expanded(
                child: TextInputField(
                  label: "Reference Number", 
                  controller: refNoController,
                  hint: "",
                ),
              ),
              SizedBox(width: 16),
              
              Expanded(
                child: FileUploadField(
                  label: "Screenshot of Receipt", 
                  hint: "Upload PNG or JPEG",
                  fileName: receiptController.text,
                  onTap: () async {
                      final XFile? file = await _picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      
                      if (file != null) {
                        setState(() {
                          proofOfPaymentFile = file;
                        });
                      }
                    },
                )
              ),

            ],
          ),
        ];



      case "Bank Transfer":
        return [
          Row(
            children: [
              Expanded(
                child: NumberInputField(
                  label: "Amount Paid",
                  controller: amountPaidController,
                  hint: "₱0"
                ),
              ),              
              SizedBox(width: 16),

              Expanded(
                child: DateInputField(
                  label: "Date of Bank Deposit",
                  controller: paymentDateController,
                ),
              ),
              SizedBox(width: 16),

              Expanded(
                child: TextInputField(
                  label: "Bank Name",
                  controller: bankNameController,
                  hint: "e.g. BPI",
                ),
              )

            ],
          ),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Column(
        children: [

          // top nav bar
          const TopNavBar(splash: "Member"),

          // main area
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // sidebar
                const SideMenu(role: "Member"),

                // main content
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [

                          // title
                          const Text(
                            "Payment Form",
                            style: TextStyle(fontSize: 28, 
                            fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            "Log your Payment",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),

                          // download button
                          buttonsRow(),

                          // payment form
                          Expanded( 
                            child: Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),

                            // form content
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  
                                  // Payment Information
                                  paymentInfo(),                                    
                                  SizedBox(height: 40),

                                  // Submit button
                                  Center( 
                                    child: ElevatedButton.icon(
                                      onPressed: _isSubmitting ? null : submitPayment,
                                      label: _isSubmitting
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Text(
                                              "Submit Payment",
                                              style: TextStyle(color: Colors.white),
                                            ),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                                        backgroundColor: Colors.black,
                                        minimumSize: const Size(100, 28),
                                      ),
                                    ),
                                  )

                                ],
                              ),
                            ),


                            ),
                          ),


                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      
    );
  }

  // Submit Payment Function
  Future<void> submitPayment() async {
    if (_isSubmitting) return;
    
    setState(() => _isSubmitting = true);

    try {
      // Validation
      if (selectedPaymentMethod == null) {
        _showError("Please select a payment method");
        return;
      }

      final amountText = amountPaidController.text.trim();
      if (amountText.isEmpty) {
        _showError("Please enter the payment amount");
        return;
      }

      final amount = double.tryParse(amountText);
      if (amount == null || amount <= 0) {
        _showError("Please enter a valid amount");
        return;
      }

      // Method-specific validation
      if (selectedPaymentMethod == 'Cash') {
        if (paymentDateController.text.trim().isEmpty) {
          _showError("Please enter the date of payment");
          return;
        }
        if (staffController.text.trim().isEmpty) {
          _showError("Please enter the staff handling payment");
          return;
        }
      } else if (selectedPaymentMethod == 'Gcash') {
        if (refNoController.text.trim().isEmpty) {
          _showError("Please enter the GCash reference number");
          return;
        }
        if (proofOfPaymentFile == null) {
          _showError("Please upload screenshot of receipt");
          return;
        }
      } else if (selectedPaymentMethod == 'Bank Transfer') {
        if (paymentDateController.text.trim().isEmpty) {
          _showError("Please enter the bank deposit date");
          return;
        }
        if (bankNameController.text.trim().isEmpty) {
          _showError("Please enter the bank name");
          return;
        }
      }

      // Get current user's member ID
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        _showError("No authenticated user found");
        return;
      }

      // Fetch member record
      final memberRecord = await Supabase.instance.client
          .from('members')
          .select('id')
          .eq('email_address', currentUser.email!)
          .maybeSingle();

      if (memberRecord == null) {
        _showError("Member record not found");
        return;
      }

      final memberId = memberRecord['id'] as int;

      // Fetch member's active approved loan from approved_loans (use application_id)
      // Note: approved_loans.status uses 'active' not 'Approved'
      final loanRecord = await Supabase.instance.client
          .from('approved_loans')
          .select('application_id, repayment_term, loan_amount')
          .eq('member_id', memberId)
          .eq('status', 'active')
          .maybeSingle();

      if (loanRecord == null) {
        _showError("No active approved loan found for this member");
        return;
      }

      final loanId = loanRecord['application_id'] as int;
      // Note: repayment_term and loan_amount can be used for validation if needed

      // Calculate installment number based on existing payments
      final existingPaymentsResp = await Supabase.instance.client
          .from('payments')
          .select('payment_id')
          .eq('loan_id', loanId);

      final installmentNumber = (existingPaymentsResp as List).length + 1;

      // Parse payment date (for Cash and Bank Transfer)
      DateTime? paymentDate;
      if (selectedPaymentMethod == 'Cash' || selectedPaymentMethod == 'Bank Transfer') {
        try {
          final dateParts = paymentDateController.text.split('/');
          if (dateParts.length == 3) {
            paymentDate = DateTime(
              int.parse(dateParts[2]),
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
            );
          }
        } catch (_) {
          _showError("Invalid date format. Use MM/DD/YYYY");
          return;
        }
      }

      // Handle GCash screenshot upload
      String? gcashScreenshotPath;
      if (selectedPaymentMethod == 'Gcash' && proofOfPaymentFile != null) {
        final fileName = 'gcash_${DateTime.now().millisecondsSinceEpoch}_${proofOfPaymentFile!.name}';
        final bytes = await proofOfPaymentFile!.readAsBytes();

        try {
          // upload binary
          await Supabase.instance.client.storage
              .from('payment_receipts')
              .uploadBinary(fileName, bytes);

          // Try to get public URL (works if bucket is public). Be defensive about return types.
          try {
            final publicUrlRes = await Supabase.instance.client.storage
                .from('payment_receipts')
                .getPublicUrl(fileName);
            String? publicUrl;
            final resp = publicUrlRes as dynamic;
            try {
              if (resp is String) {
                publicUrl = resp;
              } else if (resp is Map) {
                publicUrl = (resp['publicUrl'] ?? resp['publicURL'] ?? resp['public_url']) as String?;
                if (publicUrl == null && resp['data'] != null) {
                  final d = resp['data'];
                  if (d is String) publicUrl = d;
                  if (d is Map) publicUrl = (d['publicUrl'] ?? d['publicURL'] ?? d['public_url']) as String?;
                }
              }
            } catch (_) {
              // ignore parsing errors
            }

            if (publicUrl != null && publicUrl.isNotEmpty) {
              gcashScreenshotPath = publicUrl;
            } else {
              gcashScreenshotPath = fileName; // fallback
            }
          } catch (_) {
            // fallback if getPublicUrl not available
            gcashScreenshotPath = fileName;
          }
        } catch (e) {
          _showError('Failed to upload screenshot: $e');
          return;
        }
      }

      // Lookup staff ID for Cash payments
      int? staffId;
      if (selectedPaymentMethod == 'Cash') {
        final staffName = staffController.text.trim();
        final staffRecord = await Supabase.instance.client
            .from('staff')
            .select('id')
            .or('first_name.ilike.%$staffName%,last_name.ilike.%$staffName%')
            .maybeSingle();
        
        if (staffRecord != null) {
          staffId = staffRecord['id'] as int;
        }
      }

      // Prepare payment payload
      final Map<String, dynamic> paymentPayload = {
        'loan_id': loanId,
        'amount': amount,
        'installment_number': installmentNumber,
        'payment_type': selectedPaymentMethod,
        'status': 'Pending Approval',
      };

      if (staffId != null) {
        paymentPayload['staff_id'] = staffId;
      }

      if (paymentDate != null) {
        paymentPayload['payment_date'] = paymentDate.toIso8601String();
      }

      if (selectedPaymentMethod == 'Bank Transfer') {
        paymentPayload['bank_deposit_date'] = paymentDate?.toIso8601String();
        paymentPayload['bank_name'] = bankNameController.text.trim();
      }

      if (selectedPaymentMethod == 'Gcash') {
        paymentPayload['gcash_reference'] = refNoController.text.trim();
        if (gcashScreenshotPath != null) {
          paymentPayload['gcash_screenshot_path'] = gcashScreenshotPath;
        }
      }

      // Insert payment record
      await Supabase.instance.client
          .from('payments')
          .insert(paymentPayload);

      // Show success dialog
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Payment submitted successfully and is pending validation.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Reset form
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MemberPaymentForm()),
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );

    } catch (e) {
      debugPrint('Payment submission error: $e');
      _showError('Failed to submit payment: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

}