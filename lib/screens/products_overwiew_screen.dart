import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_complete_guide/providers/cart.dart';
import 'package:flutter_complete_guide/providers/products.dart';
import 'package:flutter_complete_guide/widgets/cart_badge.dart';
import 'package:flutter_complete_guide/widgets/my_drawer.dart';
import 'package:provider/provider.dart';
import '../widgets/products_grid.dart';

enum filterOptions { Favorites, All }

class ProductOverwiewScreen extends StatefulWidget {
  static const route = '/';

  @override
  State<ProductOverwiewScreen> createState() => _ProductOverwiewScreenState();
}

class _ProductOverwiewScreenState extends State<ProductOverwiewScreen> {
  bool _showFavoritesOnly = false;
  var isInit = true;
  var isLoading = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (isInit) {
      isLoading = true;
      final products = Provider.of<Products>(context);
      products.fetchProductsFromFirebase().then((_) {
        isLoading = false;
      });
    }
    isInit = false;

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    // final cart = Provider.of<Cart>(context);
    return Scaffold(
      drawer: MyDrawer(),
      appBar: AppBar(
        actions: [
          CartBadge(),
          PopupMenuButton(
            color: Colors.purple[200],
            itemBuilder: (_) => [
              PopupMenuItem(
                child: Text('Ulubione'),
                value: filterOptions.Favorites,
              ),
              PopupMenuItem(
                child: Text('Wszystkie'),
                value: filterOptions.All,
              ),
            ],
            onSelected: (filterOptions selectedValue) {
              setState(() {
                selectedValue == filterOptions.All
                    ? _showFavoritesOnly = false
                    : _showFavoritesOnly = true;
              });
            },
          ),
        ],
        title: Text("Sklep CBD "),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ProductsGrid(_showFavoritesOnly),
    );
  }
}
