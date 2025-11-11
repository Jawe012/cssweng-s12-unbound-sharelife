import 'package:flutter/material.dart';
import 'package:the_basics/core/widgets/top_navbar.dart';
import 'package:the_basics/core/widgets/side_menu.dart';
import 'package:image_picker/image_picker.dart';

class AdminFinanceManagement extends StatefulWidget {
  const AdminFinanceManagement({super.key});

  @override
  State<AdminFinanceManagement> createState() => _AdminFinanceManagementState();
}

class _AdminFinanceManagementState extends State<AdminFinanceManagement> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();

  // Voucher Application fields
  final TextEditingController refNumberController = TextEditingController();
  final TextEditingController payToController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController satelliteOfficeController = TextEditingController();
  final TextEditingController bankController = TextEditingController();
  final TextEditingController checkNumberController = TextEditingController();
  final TextEditingController receivedSumController = TextEditingController();

  // Dynamic rows
  List<Map<String, dynamic>> particularsRows = [
    {'particular': TextEditingController(), 'amount': TextEditingController()}
  ];
  List<Map<String, dynamic>> accountRows = [
    {'title': TextEditingController(), 'debit': TextEditingController(), 'credit': TextEditingController()}
  ];

  // Signature fields
  final TextEditingController preparedNameController = TextEditingController();
  final TextEditingController preparedDateController = TextEditingController();
  final TextEditingController checkedNameController = TextEditingController();
  final TextEditingController checkedDateController = TextEditingController();
  final TextEditingController approvedNameController = TextEditingController();
  final TextEditingController approvedDateController = TextEditingController();
  final TextEditingController receivedNameController = TextEditingController();
  final TextEditingController receivedDateController = TextEditingController();

  XFile? preparedSignature;
  XFile? checkedSignature;
  XFile? approvedSignature;
  XFile? receivedSignature;

  // Voucher Search
  String? searchType = 'Reference Number';
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> vouchers = [];
  List<Map<String, dynamic>> filteredVouchers = [];
  bool isLoadingVouchers = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchVouchers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    refNumberController.dispose();
    payToController.dispose();
    dateController.dispose();
    satelliteOfficeController.dispose();
    bankController.dispose();
    checkNumberController.dispose();
    receivedSumController.dispose();
    searchController.dispose();
    
    for (var row in particularsRows) {
      row['particular'].dispose();
      row['amount'].dispose();
    }
    for (var row in accountRows) {
      row['title'].dispose();
      row['debit'].dispose();
      row['credit'].dispose();
    }
    
    preparedNameController.dispose();
    preparedDateController.dispose();
    checkedNameController.dispose();
    checkedDateController.dispose();
    approvedNameController.dispose();
    approvedDateController.dispose();
    receivedNameController.dispose();
    receivedDateController.dispose();
    
    super.dispose();
  }

  void _addParticularsRow() {
    setState(() {
      particularsRows.add({
        'particular': TextEditingController(),
        'amount': TextEditingController(),
      });
    });
  }

  void _removeParticularsRow(int index) {
    if (particularsRows.length > 1) {
      setState(() {
        particularsRows[index]['particular'].dispose();
        particularsRows[index]['amount'].dispose();
        particularsRows.removeAt(index);
      });
    }
  }

  void _addAccountRow() {
    setState(() {
      accountRows.add({
        'title': TextEditingController(),
        'debit': TextEditingController(),
        'credit': TextEditingController(),
      });
    });
  }

  void _removeAccountRow(int index) {
    if (accountRows.length > 1) {
      setState(() {
        accountRows[index]['title'].dispose();
        accountRows[index]['debit'].dispose();
        accountRows[index]['credit'].dispose();
        accountRows.removeAt(index);
      });
    }
  }

  Future<void> _pickSignature(String type) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          switch (type) {
            case 'prepared':
              preparedSignature = image;
              break;
            case 'checked':
              checkedSignature = image;
              break;
            case 'approved':
              approvedSignature = image;
              break;
            case 'received':
              receivedSignature = image;
              break;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting signature: $e')),
      );
    }
  }

  Future<void> _submitVoucher() async {
    // TODO: Implement voucher submission to database
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Voucher submitted successfully'), backgroundColor: Colors.green),
    );
  }

  void _downloadTemplate() {
    // TODO: Implement template download
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Template download coming soon')),
    );
  }

  Future<void> _fetchVouchers() async {
    setState(() => isLoadingVouchers = true);

    try {
      // TODO: Fetch from actual vouchers table
      // For now using mock data
      setState(() {
        vouchers = [
          {'vouch_id': 'V-001', 'loan_id': 'L-1001', 'member_name': 'Juan Dela Cruz', 'amount': "2500", 'date_issued': '2025-11-10'},
          {'vouch_id': 'V-002', 'loan_id': 'L-1002', 'member_name': 'Maria Santos', 'amount': "3200", 'date_issued': '2025-11-09'},
          {'vouch_id': 'V-003', 'loan_id': 'L-1003', 'member_name': 'Pedro Ramirez', 'amount': "1800", 'date_issued': '2025-11-08'},
          {'vouch_id': 'V-004', 'loan_id': 'L-1004', 'member_name': 'Ana Dizon', 'amount': "4100", 'date_issued': '2025-11-07'},
          {'vouch_id': 'V-005', 'loan_id': 'L-1005', 'member_name': 'Liza Manalo', 'amount': "2750", 'date_issued': '2025-11-06'},
        ];
        filteredVouchers = vouchers;
        isLoadingVouchers = false;
      });
    } catch (e) {
      setState(() => isLoadingVouchers = false);
    }
  }

  void _filterVouchers() {
    final query = searchController.text.toLowerCase();
    
    setState(() {
      if (query.isEmpty) {
        filteredVouchers = vouchers;
      } else {
        filteredVouchers = vouchers.where((voucher) {
          switch (searchType) {
            case 'Reference Number':
              return voucher['ref_number'].toString().toLowerCase().contains(query);
            case 'Date':
              return voucher['date'].toString().contains(query);
            case 'Member Name':
              return voucher['member_name'].toString().toLowerCase().contains(query);
            default:
              return false;
          }
        }).toList();
      }
    });
  }

  Widget _buildSignatureField(String label, String type, XFile? signature, 
  TextEditingController nameController, TextEditingController dateController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        SizedBox(
          width: 150,
          child: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: "Name",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          ),
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: () => _pickSignature(type),
          child: Container(
            width: 150,
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: signature != null
                  ? Text('Signature', style: TextStyle(fontSize: 12))
                  : Text('Upload Signature', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          ),
        ),
        SizedBox(height: 8),
        SizedBox(
          width: 150,
          child: TextField(
            controller: dateController,
            decoration: InputDecoration(
              labelText: "Date",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget voucherInfo() {
    return Column(
      children: [
        Row(
          children: [
            Flexible(
              child: TextField(
                controller: refNumberController,
                decoration: InputDecoration(
                  labelText: "Reference Number",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 12),
            Flexible(
              child: TextField(
                controller: payToController,
                decoration: InputDecoration(
                  labelText: "Pay to",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 12),
            Flexible(
              child: TextField(
                controller: dateController,
                decoration: InputDecoration(
                  labelText: "Date",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Row 2: Satellite Office, Bank, Check #
        Row(
          children: [
            Flexible(
              child: TextField(
                controller: satelliteOfficeController,
                decoration: InputDecoration(
                  labelText: "Satellite Office Unit",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 12),
            Flexible(
              child: TextField(
                controller: bankController,
                decoration: InputDecoration(
                  labelText: "Bank",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 12),
            Flexible(
              child: TextField(
                controller: checkNumberController,
                decoration: InputDecoration(
                  labelText: "Check Number",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget particulars() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Particulars", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              icon: Icon(Icons.add_circle, color: Colors.blue),
              onPressed: _addParticularsRow,
            ),
          ],
        ),
        SizedBox(height: 8),
        ...particularsRows.asMap().entries.map((entry) {
          int index = entry.key;
          var row = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Flexible(
                  flex: 2,
                  child: TextField(
                    controller: row['particular'],
                    decoration: InputDecoration(
                      labelText: "Particular",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Flexible(
                  child: TextField(
                    controller: row['amount'],
                    decoration: InputDecoration(
                      labelText: "Amount",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                if (particularsRows.length > 1)
                  IconButton(
                    icon: Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _removeParticularsRow(index),
                  ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget accountTitle() {
    return Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Account Title", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              icon: Icon(Icons.add_circle, color: Colors.blue),
              onPressed: _addAccountRow,
            ),
          ],
        ),
        SizedBox(height: 8),
        ...accountRows.asMap().entries.map((entry) {
          int index = entry.key;
          var row = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: row['title'],
                    decoration: InputDecoration(
                      labelText: "Title",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: row['debit'],
                    decoration: InputDecoration(
                      labelText: "Debit",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: row['credit'],
                    decoration: InputDecoration(
                      labelText: "Credit",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                if (accountRows.length > 1)
                  IconButton(
                    icon: Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _removeAccountRow(index),
                  ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget sumAndSignatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        // Received Sum
        TextField(
          controller: receivedSumController,
          decoration: InputDecoration(
            labelText: "Received from K-Coop the sum of",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        SizedBox(height: 30),

        // Signatures Section
        Text("Signatures", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(child: _buildSignatureField("Prepared by", "prepared", preparedSignature, preparedNameController, preparedDateController)),
            SizedBox(width: 16),
            Flexible(child: _buildSignatureField("Checked by", "checked", checkedSignature, checkedNameController, checkedDateController)),
            SizedBox(width: 16),
            Flexible(child: _buildSignatureField("Approved by", "approved", approvedSignature, approvedNameController, approvedDateController)),
            SizedBox(width: 16),
            Flexible(child: _buildSignatureField("Received by", "received", receivedSignature, receivedNameController, receivedDateController)),
          ],
        ),
      ]
    );
  }

  Widget vouchSearchBar() {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                value: searchType,
                decoration: InputDecoration(
                  labelText: "Search by",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: [
                  DropdownMenuItem(value: "Reference Number", child: Text("Reference No.")),
                  DropdownMenuItem(value: "Date", child: Text("Date")),
                  DropdownMenuItem(value: "Member Name", child: Text("Member Name")),
                ],
                onChanged: (value) {
                  setState(() {
                    searchType = value;
                    _filterVouchers();
                  });
                },
              ),
            ),
            SizedBox(width: 16),
            Flexible(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: "Search",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (_) => _filterVouchers(),
              ),
            ),
            SizedBox(width: 16),
            ElevatedButton(
              onPressed: _filterVouchers,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: Text("Search", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }

  Widget vouchSearchTable() {
    return Column(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: isLoadingVouchers
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text("Voucher ID", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Loan ID", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Member Name", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Date Issued", style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: filteredVouchers.map((voucher) {
                        return DataRow(cells: [
                          DataCell(Text(voucher['vouch_id'])),
                          DataCell(Text(voucher['loan_id'])),
                          DataCell(Text(voucher['member_name'])),
                          DataCell(Text(voucher['amount'])),
                          DataCell(Text(voucher['date_issued'])),
                        ]);
                      }).toList(),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFEFEF),
      body: Column(
        children: [
          TopNavBar(splash: "Admin"),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SideMenu(role: "Admin"),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: 16),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title
                        Text(
                          "Voucher Generation",
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Create and manage check vouchers",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        SizedBox(height: 24),
                        
                        // Tabs
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            labelColor: Colors.blue,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Colors.blue,
                            tabs: [
                              Tab(text: "Voucher Application"),
                              Tab(text: "Voucher Search"),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                        
                        // Tab Content
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [



                              
                              // TAB 1: VOUCHER APPLICATION
                              SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    
                                    // Header with download button
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Check Voucher",
                                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: _downloadTemplate,
                                          icon: Icon(Icons.download, color: Colors.white, size: 18),
                                          label: Text("Download Template", style: TextStyle(color: Colors.white)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.black,
                                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16),

                                    // Main Form Card
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
                                          
                                          // Header
                                          Text(
                                            "Sharelife Multi-Purpose Cooperative",
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            "Visayas St., Phase 4, Lupang Pangako, Payatas, Quezon City",
                                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                          ),
                                          SizedBox(height: 24),

                                          // First block
                                          voucherInfo(),
                                          SizedBox(height: 24),

                                          // Particulars Section
                                          particulars(),
                                          SizedBox(height: 24),

                                          // Account Title Section
                                          accountTitle(),
                                          SizedBox(height: 24),

                                          // Received sum + signatures
                                          sumAndSignatures(),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 24),

                                    // Submit Button
                                    Center(
                                      child: ElevatedButton(
                                        onPressed: _submitVoucher,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.black,
                                          padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: Text("Submit Voucher", style: TextStyle(color: Colors.white, fontSize: 16)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),




                              // TAB 2: VOUCHER SEARCH
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  
                                  // Search Bar
                                  vouchSearchBar(),
                                  SizedBox(height: 24),

                                  // Vouchers Table
                                  vouchSearchTable(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
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
}