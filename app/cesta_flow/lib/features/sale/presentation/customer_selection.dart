import 'package:cesta_flow/core/data/local/model/customer_model.dart';
import 'package:cesta_flow/core/data/local/repository/customer_repository.dart';
import 'package:flutter/material.dart';

class CustomerSelection extends StatefulWidget {
  const CustomerSelection({super.key});

  @override
  State<CustomerSelection> createState() => _CustomerSelectionState();
}

class _CustomerSelectionState extends State<CustomerSelection> {
  Future<List<Customer>> _customers = Future.value([]);
  List<Customer> _filteredCustomers = [];

  @override
  void initState() {
    super.initState();
    _customers = CustomerRepository().getAllCustomers();
    _customers.then((customers) {
      setState(() {
        _filteredCustomers = customers;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Selecionar Cliente',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<Customer>>(
        future: _customers,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                spacing: 16,
                children: [
                  SearchBar(
                    hintText: 'Digite o nome ou CPF do cliente',
                    onChanged: (searchQuery) {
                      setState(() {
                        _filteredCustomers = filterCustomers(
                          snapshot.data!,
                          searchQuery,
                        );
                      });
                    },
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/customerRegistration',
                      ).then((value) {
                        if (value != null && value is Customer) {
                          setState(() {
                            _filteredCustomers.add(value);
                          });
                        }
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      fixedSize: Size(double.infinity, 64),
                      side: BorderSide(color: Colors.green, width: 2),
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                    child: Text(
                      'Cadastrar Novo Cliente',
                      style: TextStyle(fontSize: 20, color: Colors.green),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredCustomers.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                            '${_filteredCustomers[index].name}, CPF: ${_filteredCustomers[index].documentCPF}',
                          ),
                          onTap: () {
                            Navigator.pop(context, _filteredCustomers[index]);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar clientes'));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

List<Customer> filterCustomers(List<Customer> customers, String query) {
  if (query.isEmpty) {
    return customers;
  } else {
    final cleanQueryCPF = query.replaceAll(RegExp(r'[^0-9]'), '');
    return customers
        .where(
          (customer) =>
              customer.name.toLowerCase().contains(query.toLowerCase()) ||
              (cleanQueryCPF.isNotEmpty &&
                  customer.documentCPF
                      .replaceAll(RegExp(r'[^0-9]'), '')
                      .contains(cleanQueryCPF)),
        )
        .toList();
  }
}
