import 'dart:io';

import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/modules/product/bindings/product_binding.dart';
import 'package:semesta_pos/modules/product/controllers/product_controller.dart';
import 'package:semesta_pos/styles/app_theme.dart';

class ProductScreen extends StatelessWidget {
  const ProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProductController());
    ProductBinding().dependencies;
    controller.resetStateStore();

    controller.getProductData();
    controller.getCategory();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(
          () => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Products',
                          style: TextStyle(fontFamily: AppTheme.fontBold, fontSize: AppTheme.fontSizeTitleMedium),
                        ),
                        subtitle: Text(
                          'Manage your product inventory here.',
                          style: TextStyle(fontFamily: AppTheme.fontRegular, fontSize: AppTheme.fontSizeCaption),
                        ),
                      ),
                      TextField(
                        onChanged: (value) {
                          controller.searchProduct(value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search product...',
                          hintStyle: TextStyle(
                            fontFamily: AppTheme.fontRegular,
                            fontSize: AppTheme.fontSizeLabelSmall,
                            color: Colors.grey,
                          ),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10.h,
                      ),
                      if (controller.isLoadingProduct.value)
                        Align(
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            backgroundColor: Colors.blue[50],
                            color: Colors.blue,
                          ),
                        )
                      else if (controller.productModelList.isEmpty)
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            'No data available.',
                            style: TextStyle(
                              fontFamily: AppTheme.fontMedium,
                              fontSize: AppTheme.fontSizeLabelMedium,
                              color: Colors.black,
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          padding: EdgeInsets.only(top: 20.h),
                          scrollDirection: Axis.vertical,
                          itemCount: controller.productModelList.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            var productList =
                                controller.productModelList[index];
                            return GestureDetector(
                              onTap: () {
                                controller.productModel = productList;
                                controller.setProductEdit();
                                // print(controller.productModel.toString());
                              },
                              child: ListTile(
                                contentPadding: EdgeInsets.only(top: 10.h),
                                leading: Image.network(
                                  '${controller.userService.getBaseUrl()}data/${productList.img ?? ""}',
                                  errorBuilder: (context, error, stackTrace) {
                                    // print(error.toString());
                                    return const Icon(Icons.error);
                                  },
                                ),
                                title: Text(
                                  productList.namaProduk.toString(),
                                  style: TextStyle(
                                      fontFamily: AppTheme.fontMedium,
                                      color: Colors.black,
                                      fontSize: AppTheme.fontSizeMicro),
                                ),
                                subtitle: Text(
                                  'X${productList.stok.toString()}',
                                  style: TextStyle(
                                      fontFamily: AppTheme.fontRegular,
                                      color: Colors.grey,
                                      fontSize: AppTheme.fontSizeMicro),
                                ),
                                trailing: GestureDetector(
                                  onTap: () async {
                                    await controller
                                        .destroy(productList.idProduk);
                                  },
                                  child: const ClipRRect(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(10)),
                                    child: SizedBox(
                                      // Replaced Container with SizedBox
                                      // color: Colors.red[50], // Removed color property as SizedBox does not have it
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Icon(
                                          CupertinoIcons.delete,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: ScreenUtil().setWidth(20),
              ),
              Container(
                padding: EdgeInsets.only(top: 10.h, right: 10.w),
                width: 160.w,
                child: controller.isLoadingCategory.value
                    ? Center(
                        child: CircularProgressIndicator(
                          backgroundColor: Colors.blue[50],
                          color: Colors.blue,
                        ),
                      )
                    : controller.categoryModelList.isEmpty
                        ? Center(
                            child: Center(
                              child: Text(
                                'Failed to load categories.',
                                style: TextStyle(
                                    fontFamily: AppTheme.fontMedium,
                                    fontSize: AppTheme.fontSizeMicro,
                                    color: Colors.grey),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  controller.isEditable.value
                                      ? "Edit Product"
                                      : "Add New Product",
                                  style: TextStyle(
                                      fontFamily: AppTheme.fontBold, fontSize: AppTheme.fontSizeTiny),
                                ),
                                SizedBox(
                                  height: 15.h,
                                ),
                                TextField(
                                  controller: controller.namaProductController,
                                  decoration: InputDecoration(
                                    labelStyle: TextStyle(
                                      color: Colors.black,
                                      fontFamily: AppTheme.fontMedium,
                                      fontSize: AppTheme.fontSizeMicro,
                                    ),
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.always,
                                    labelText: 'Product Name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: Colors.blue, width: 2.0),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 10.h,
                                ),
                                DropdownSearch<String>(
                                    dropdownDecoratorProps:
                                        DropDownDecoratorProps(
                                      baseStyle: TextStyle(
                                        color: Colors.black,
                                        fontFamily: 'popmed',
                                        fontSize: 6.sp,
                                      ),
                                      dropdownSearchDecoration: InputDecoration(
                                        hintStyle: TextStyle(
                                          color: Colors.black,
                                          fontFamily: AppTheme.fontMedium,
                                          fontSize: AppTheme.fontSizeMicro,
                                        ),
                                        labelText: "Select category",
                                        labelStyle: TextStyle(
                                            fontFamily: AppTheme.fontMedium,
                                            fontSize: AppTheme.fontSizeMicro,
                                            color: Colors.black),
                                        hintText: "Type or select a category",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              10), // Menambahkan border radius pada spinner
                                        ),
                                      ),
                                    ),
                                    popupProps: PopupProps.menu(
                                      showSearchBox: true,
                                      searchFieldProps: TextFieldProps(
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontFamily: AppTheme.fontMedium,
                                          fontSize: AppTheme.fontSizeMicro,
                                        ),
                                        decoration: InputDecoration(
                                          labelStyle: TextStyle(
                                            color: Colors.black,
                                            fontFamily: AppTheme.fontMedium,
                                            fontSize: AppTheme.fontSizeMicro,
                                          ),
                                          hintText: 'Category',
                                          floatingLabelBehavior:
                                              FloatingLabelBehavior.always,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          labelText: 'Search category',
                                        ),
                                      ),
                                      showSelectedItems: true,
                                      menuProps: const MenuProps(
                                        shape: RoundedRectangleBorder(
                                          // Menambahkan border radius pada menu
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(20)),
                                        ),
                                      ),
                                    ),
                                    itemAsString: (String itemId) {
                                      final categoryName = controller
                                          .categoryModelList
                                          .firstWhere((item) =>
                                              item.idKategori.toString() ==
                                              itemId)
                                          .namaKategori;
                                      return categoryName!;
                                    },
                                    items: controller.categoryModelList
                                        .map((item) =>
                                            item.idKategori.toString())
                                        .toList(),
                                    onChanged: (value) {
                                      controller.kategoriId = value.toString();
                                      // controller.countDiscount();
                                      // controller.memberId.value = int.parse(value!);
                                    }),
                                SizedBox(
                                  height: 10.h,
                                ),
                                TextField(
                                  controller: controller.merkProductController,
                                  decoration: InputDecoration(
                                    labelStyle: TextStyle(
                                      color: Colors.black,
                                      fontFamily: AppTheme.fontMedium,
                                      fontSize: AppTheme.fontSizeMicro,
                                    ),
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.always,
                                    labelText: 'Brand',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: Colors.blue, width: 2.0),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 10.h,
                                ),
                                TextField(
                                  controller:
                                      controller.hrgBeliProductController,
                                  inputFormatters: [
                                    CurrencyTextInputFormatter.currency(
                                      locale: 'ID',
                                      decimalDigits: 0,
                                      symbol: 'Rp. ',
                                    ),
                                  ],
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelStyle: TextStyle(
                                      color: Colors.black,
                                      fontFamily: AppTheme.fontMedium,
                                      fontSize: AppTheme.fontSizeMicro,
                                    ),
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.always,
                                    labelText: 'Cost Price',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: Colors.blue, width: 2.0),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 10.h,
                                ),
                                TextField(
                                  controller:
                                      controller.hrgJualProductController,
                                  inputFormatters: [
                                    CurrencyTextInputFormatter.currency(
                                      locale: 'ID',
                                      decimalDigits: 0,
                                      symbol: 'Rp. ',
                                    ),
                                  ],
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelStyle: TextStyle(
                                      color: Colors.black,
                                      fontFamily: AppTheme.fontMedium,
                                      fontSize: AppTheme.fontSizeMicro,
                                    ),
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.always,
                                    labelText: 'Selling Price',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: Colors.blue, width: 2.0),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 10.h,
                                ),
                                TextField(
                                  keyboardType: TextInputType.number,
                                  controller:
                                      controller.diskonProductController,
                                  decoration: InputDecoration(
                                    labelStyle: TextStyle(
                                      color: Colors.black,
                                      fontFamily: AppTheme.fontMedium,
                                      fontSize: AppTheme.fontSizeMicro,
                                    ),
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.always,
                                    labelText: 'Discount',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: Colors.blue, width: 2.0),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 10.h,
                                ),
                                TextField(
                                  keyboardType: TextInputType.number,
                                  controller: controller.stokProductController,
                                  decoration: InputDecoration(
                                    labelStyle: TextStyle(
                                      color: Colors.black,
                                      fontFamily: AppTheme.fontMedium,
                                      fontSize: AppTheme.fontSizeMicro,
                                    ),
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.always,
                                    labelText: 'Stock',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: Colors.blue, width: 2.0),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 10.h,
                                ),
                                if (controller.isEditable.value &&
                                    controller.imageFile.value == '')
                                  SizedBox(
                                      width: 60.w,
                                      height: 60.h,
                                      child: Image.network(
                                        '${controller.userService.getBaseUrl()}data/${controller.productModel.img ?? ""}',
                                      ))
                                else if (controller.imageFile.value != '')
                                  SizedBox(
                                    width: 60.w,
                                    height: 60.h,
                                    child: Image.file(
                                        File(controller.imageFile.value)),
                                  )
                                else
                                  Container(),
                                TextButton(
                                  onPressed: () async {
                                    await controller.getImage();
                                  },
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(
                                      Colors.green[50],
                                    ),
                                  ),
                                  child: Text(
                                    'Select Image',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontMedium,
                                      fontSize: AppTheme.fontSizeMicro,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 20.h,
                                ),
                                Stack(
                                  children: [
                                    controller.isLoadingStore.value == true
                                        ? Align(
                                            alignment: Alignment.topRight,
                                            child: CircularProgressIndicator(
                                              backgroundColor: Colors.blue[50],
                                              color: Colors.blue,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: TextButton(
                                                  onPressed: () {
                                                    controller.resetStateStore();
                                                  },
                                                  style: ButtonStyle(
                                                    backgroundColor:
                                                        WidgetStatePropertyAll(
                                                      Colors.red[50],
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Reset',
                                                    style: TextStyle(
                                                      fontFamily: AppTheme.fontMedium,
                                                      fontSize: AppTheme.fontSizeMicro,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 8.w),
                                              Expanded(
                                                child: TextButton(
                                                  onPressed: () {
                                                    controller.inputValidation();
                                                  },
                                                  style: ButtonStyle(
                                                    backgroundColor:
                                                        WidgetStatePropertyAll(
                                                      Colors.blue[50],
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Save',
                                                    style: TextStyle(
                                                      fontFamily: AppTheme.fontMedium,
                                                      fontSize: AppTheme.fontSizeMicro,
                                                      color: Colors.blue,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                  ],
                                ),
                                SizedBox(
                                  height: 20.h,
                                ),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
