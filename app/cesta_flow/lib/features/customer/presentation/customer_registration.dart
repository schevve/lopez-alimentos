import 'package:cesta_flow/core/data/local/db_helper.dart';
import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomerRegistration extends StatefulWidget {
  const CustomerRegistration({super.key});

  @override
  State<CustomerRegistration> createState() => _CustomerRegistrationState();
}

class _CustomerRegistrationState extends State<CustomerRegistration> {
  final _formKey = GlobalKey<FormState>();
  final _formData = <String, dynamic>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF3FCF3),

      appBar: AppBar(
        backgroundColor: const Color(0xff1C5631),

        flexibleSpace: Container(
          decoration: BoxDecoration(
            image:DecorationImage(
              image: AssetImage('web/images/FundoComidas.png'),
              fit: BoxFit.cover
            )
          ),
        ),

        toolbarHeight: 70,
        title: Text(
          'Registrar Cliente',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton.filled(
          icon: const Icon(Icons.arrow_back,
            color: Colors.white
          ),
          style: IconButton.styleFrom(
            backgroundColor: const Color.fromARGB(48, 255, 255, 255)
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Container(width: 4,
              height: 24,
              color: Colors.orange
              ),

              SizedBox(width: 8,),

              Icon(
                Icons.person_add_alt_1_outlined,
                color: Colors.orange,
                size: 22
              ),

              SizedBox(width: 8,),

              Text(
                "IDENTIFICAÇÃO",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.redAccent
                ),

              )
            ],
          ),
          Padding(padding: EdgeInsetsGeometry.all(10)),
          Form(
          key: _formKey,
          child: Column(
            spacing: 16,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Nome completo*',
                  hintText: " ",
                  prefixIcon: const Icon(
                    Icons.person,
                    color:  Color(0xff1C5631)
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30)
                  ),

                  filled: true,
                  fillColor: Colors.white
                ),
                onSaved: (value) => _formData['nome'] = value,
              ),

              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Data de Nascimento *',
                  hintText: 'dd/mm/aaaa',

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),

                  filled: true,
                  fillColor: Colors.white
                ),

                keyboardType: TextInputType.datetime,
                inputFormatters: [FormatDate()],
                onSaved: (value) => _formData['data_nascimento'] = value,
              ),

              TextFormField(
                decoration: InputDecoration(labelText: 'Email (opcional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30)
                  ),

                  filled: true,
                  fillColor: Colors.white
                ),

                keyboardType: TextInputType.emailAddress,
                
                onSaved: (value) => _formData['email'] = value,
              ),

              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Telefone *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30)
                  ),

                  filled: true,
                  fillColor: Colors.white
                ),

                keyboardType: TextInputType.phone,
                inputFormatters: [FormatPhoneNumber()],
                onSaved: (value) => _formData['telefone'] = value,
              ),

              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Rua *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30)
                  ),

                  filled: true,
                  fillColor: Colors.white
                ),

                keyboardType: TextInputType.text,
                onSaved: (value) => _formData['rua'] = value,
              ),
              
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Número *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30)
                  ),

                  filled: true,
                  fillColor: Colors.white
                ),

                keyboardType: TextInputType.number,
                onSaved: (value) => _formData['numero'] = value,
              ),

              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Cidade *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30)
                  ),

                  filled: true,
                  fillColor: Colors.white
                ),
                
                keyboardType: TextInputType.text,
                onSaved: (value) => _formData['cidade'] = value,
                validator: (value) =>
                    value?.isNotEmpty ?? false ? null : "erro",
              ),

              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Estado (opcional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30)
                  ),

                  filled: true,
                  fillColor: Colors.white
                ),

                keyboardType: TextInputType.text,
                onSaved: (value) => _formData['estado'] = value,
                validator: (value) =>
                    value?.isNotEmpty ?? false ? null : "erro",
              ),

              TextFormField(
                decoration: InputDecoration(
                  labelText: 'CEP (opcional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30)
                  ),
                  
                  filled: true,
                  fillColor: Colors.white
                ),

                keyboardType: TextInputType.number,
                onSaved: (value) => _formData['cep'] = value,
              ),

              TextFormField(
                decoration: InputDecoration(
                  labelText: 'CPF *',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30)
                  ),

                  filled: true,
                  fillColor: Colors.white
                ),
                
                keyboardType: TextInputType.number,
                onSaved: (value) => _formData['cpf'] = value,
              ),

              TextFormField(
                decoration: InputDecoration(
                  labelText: 'RG (opcional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30)
                  ),

                  filled: true,
                  fillColor: Colors.white
                ),

                keyboardType: TextInputType.number,
                onSaved: (value) => _formData['rg'] = value,
              ),

              
            ],
          ),
        ),

        ],
        ),

        
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.transparent, 
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), 
          child: FilledButton.icon(
            onPressed: () async {
              await _submitForm();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 158, 204, 174),
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)
              )
            ),
            icon: Icon(
              Icons.person_add_alt_1_outlined,
              color: Color(0xff1C5631),
              size: 26
            ),
            label: Text(
              "Registrar Cliente",
              style: TextStyle(color: Color(0xff1C5631), fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      print('Registrando cliente: ${_formData['nome']}');
      var db = DatabaseHelper();
      var customerRepository = CustomerRepository(dbHelper: db);
      var customers = await customerRepository.getAllCustomers();
      print('Clientes existentes: ${customers.length}');
      for (var customer in customers) {
        print('Cliente existente: ${customer.name}');
      }
      var customerData = Customer(
        name: _formData['nome'],
        dateOfBirth: cleanDate(_formData['data_nascimento']),
        email: _formData['email'],
        phone: _formData['telefone'],
        address: _formData['rua'],
        city: _formData['cidade'],
        state: _formData['estado'],
        cep: _formData['cep'],
        documentCPF: _formData['cpf'],
        documentRG: _formData['rg'],
      );
      await customerRepository.registerCustomer(customerData);
      print('Cliente registrado com sucesso: ${customerData.name}');
    }
  }

  DateTime cleanDate(String dateString) {
    final parts = dateString.split('/');
    if (parts.length != 3) {
      throw FormatException('Data inválida: $dateString');
    }
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);
    return DateTime(year, month, day);
  }
}

class FormatPhoneNumber extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    print('Old Value: ${oldValue.text}, New Value: ${newValue.text}');
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length == 11) {
      final match = RegExp(r'^(\d{2})(\d{5})(\d{4})$').firstMatch(digitsOnly);
      print('Digits Only: $digitsOnly, Match: $match');
      if (match != null) {
        return TextEditingValue(
          text: '(${match.group(1)}) ${match.group(2)}-${match.group(3)}',
          selection: TextSelection.collapsed(offset: 14),
        );
      }
    }
    if (digitsOnly.length > 11) {
      return oldValue;
    }
    return newValue;
  }
}

class FormatDate extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length > 8) {
      return oldValue;
    }
    String formatted = '';
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 2 || i == 4) {
        formatted += '/';
      }
      formatted += digitsOnly[i];
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
