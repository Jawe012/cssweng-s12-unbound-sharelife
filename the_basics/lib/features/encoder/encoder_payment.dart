import 'package:flutter/material.dart';
import 'package:the_basics/widgets/top_navbar.dart';
import 'package:the_basics/widgets/side_menu.dart';
import 'package:the_basics/widgets/input_fields.dart';
import 'package:image_picker/image_picker.dart';

class EncoderPaymentForm extends StatefulWidget {
  const EncoderPaymentForm({super.key});

  @override
  State<EncoderPaymentForm> createState() => _EncoderPaymentFormState();
}

class _EncoderPaymentFormState extends State<EncoderPaymentForm> {
  
  // Payment Information
  String? selectedPaymentMethod;
  final TextEditingController amountPaidController = TextEditingController();
  final TextEditingController paymentDateController = TextEditingController();

  // Payment Information
  final TextEditingController staffController = TextEditingController();
  final TextEditingController refNoController = TextEditingController();
  final TextEditingController receiptController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();
  
  // Member Information
  final TextEditingController memberNameController = TextEditingController();
  final TextEditingController memberIdController = TextEditingController();
  final TextEditingController payerNameController = TextEditingController();
  
  // File upload
  final ImagePicker _picker = ImagePicker();
  XFile? proofOfPaymentFile;


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

  Widget memberInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Member Information",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),

        // Member Name & Member ID (side by side)
        Row(
          children: [
            Expanded(
              child: TextInputField(
                label: "Member Name",
                controller: memberNameController,
                hint: "e.g. Mark Anthony",
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextInputField(
                label: "Member ID",
                controller: memberIdController,
                hint: "",
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Payer Name & Proof of Payment (side by side)
        Row(
          children: [
            Expanded(
              child: TextInputField(
                label: "Payer Name",
                controller: payerNameController,
                hint: "e.g. Mark Anthony",
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: FileUploadField(
                label: "Proof of Payment",
                hint: "Upload PNG or JPEG",
                fileName: proofOfPaymentFile?.name,
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
              ),
            ),
          ],
        ),
      ],
    );
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
                            "Encode a Payment",
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

                                  // Member Information
                                  memberInfo(),
                                  SizedBox(height: 18),


                                  // Submit button
                                  Center( 
                                    child: ElevatedButton.icon(
                                      onPressed: submitPayment,
                                      label: const Text(
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

}



// Submit function
void submitPayment() {
  print("Payment submitted!");
  // add your back-end logic here
}