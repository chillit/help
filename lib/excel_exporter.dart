import 'package:excel/excel.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:help/list.dart';

class ExcelExporter {
  static Future<void> exportToExcel(List<House> houses, BuildContext context) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Журнал посещений'];

    // **Стили**
    CellStyle headerStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#ee0003'),
      bold: true,
      fontSize: 12,
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Center,
    );

    CellStyle greenStyle = CellStyle(fontColorHex: ExcelColor.fromHexString('#33CC33')); // Зеленый
    CellStyle redStyle = CellStyle(fontColorHex: ExcelColor.fromHexString('#FF0000')); // Красный

    // **Заголовки**
    List<String> headers = [
      'Адрес',
      'Дата посещения',
      'Состав семьи',
      'Категория граждан',
      'Ф.И.О. инструктируемого',
      'Ф.И.О. должностного лица',
      'Отмечено',
    ];

    for (int col = 0; col < headers.length; col++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
      sheet.setColumnWidth(col, 30);
    }

    // **Данные домов**
    for (int row = 0; row < houses.length; row++) {
      var house = houses[row];
      int excelRow = row + 1; // Заголовки занимают первую строку
      
      sheet.appendRow([
        house.address,
        house.date,
        house.familyComposition,
        house.category,
        house.instructedName,
        house.instructorName,
        house.checked ? 'Да' : 'Нет',
      ].map((el) => TextCellValue(el)).toList());

      // Окрашивание "Отмечено"
      var checkedCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: excelRow));
      checkedCell.cellStyle = house.checked ? greenStyle : redStyle;
    }
    excel.delete(excel.getDefaultSheet()!);
    // Сохранение
    var res = excel.save(fileName: "Журнал посещений.xlsx");
    print(res);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Файл сохранен!')),
    );
  }
}
