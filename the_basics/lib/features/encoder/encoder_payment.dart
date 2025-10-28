import 'package:flutter/material.dart';
import 'package:the_basics/widgets/top_navbar.dart';
import 'package:the_basics/widgets/side_menu.dart';
import 'package:image_picker/image_picker.dart';

class EncoderPaymentForm extends StatefulWidget {
  const EncoderPaymentForm({super.key});

  @override
  State<EncoderPaymentForm> createState() => _EncoderPaymentFormState();
}

class _EncoderPaymentFormState extends State<EncoderPaymentForm> {
  
  // Payment Information
  final TextEditingController amountPaidController = TextEditingController();
  final TextEditingController loanRefController = TextEditingController();
  final TextEditingController paymentDateController = TextEditingController();
  
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

        // Amount Paid (full width)
        NumberInputField(
          label: "Amount Paid",
          controller: amountPaidController,
          hint: "₱0"
        ),
        SizedBox(height: 16),

        // Loan Reference Number & Date of Payment (side by side)
        Row(
          children: [
            Expanded(
              child: TextInputField(
                label: "Loan Reference Number",
                controller: loanRefController,
                hint: "",
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: DateInputField(
                label: "Date of Payment",
                controller: paymentDateController,
              ),
            ),
          ],
        ),
      ],
    );
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
          const TopNavBar(splash: "Encoder"),

          // main area
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // sidebar
                const SideMenu(role: "Encoder"),

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


// Reusable input field classes

class TextInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const TextInputField({
    super.key,
    required this.label,
    required this.controller,
    this.hint = "",
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
    );
  }
}

class NumberInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const NumberInputField({
    super.key, 
    required this.label, 
    required this.controller, 
    required this.hint
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
    );
  }
}

class DateInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const DateInputField({super.key, required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: "MM-DD-YYYY",
        suffixIcon: const Icon(Icons.calendar_month),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null) {
          // Format as MM-DD-YYYY to match Figma
          String month = pickedDate.month.toString().padLeft(2, '0');
          String day = pickedDate.day.toString().padLeft(2, '0');
          String year = pickedDate.year.toString();
          controller.text = "$month-$day-$year";
        }
      },
    );
  }
}

class FileUploadField extends StatelessWidget {
  final String label;
  final String hint;
  final String? fileName;
  final VoidCallback onTap;

  const FileUploadField({
    super.key,
    required this.label,
    required this.hint,
    this.fileName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Row(
              children: [
                SizedBox(width: 12),
                Icon(Icons.upload_file, color: Colors.grey[600]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName ?? hint,
                    style: TextStyle(
                      color: fileName != null ? Colors.black : Colors.grey[600],
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}