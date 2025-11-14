import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  bool _isDarkMode = false;

  // переключение темы
  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: CalculatorScreen(
        isDarkMode: _isDarkMode,
        onThemeToggle: _toggleTheme,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const CalculatorScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  String? _operation; // текущая операция
  double? _firstNumber; // первое число для операции
  bool _shouldResetDisplay = false; // нужно ли сбросить дисплей
  String? _pressedButton; // какая кнопка сейчас нажата

  void _onButtonPressed(String button) {
    setState(() {
      _pressedButton = button;
    });

    // обработка разных кнопок
    if (button == 'C') {
      _clear();
    } else if (button == '⌫') {
      _deleteLastChar();
    } else if (button == '=') {
      _calculate();
    } else if (button == 'sin') {
      _calculateSin();
    } else if (button == '+' || button == '-' || button == '×' || button == '÷' || button == '^') {
      _setOperation(button);
    } else if (button == '.') {
      _addDecimal();
    } else {
      _addDigit(button);
    }

    // сбрасываем подсветку кнопки через небольшую задержку
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _pressedButton = null;
        });
      }
    });
  }

  // очистка всего
  void _clear() {
    setState(() {
      _display = '0';
      _operation = null;
      _firstNumber = null;
      _shouldResetDisplay = false;
    });
  }

  void _addDigit(String digit) {
    setState(() {
      if (_shouldResetDisplay) {
        _display = digit;
        _shouldResetDisplay = false;
      } else {
        if (_display == '0') {
          _display = digit;
        } else {
          _display += digit;
        }
      }
    });
  }

  // добавление точки для десятичных
  void _addDecimal() {
    setState(() {
      if (_shouldResetDisplay) {
        _display = '0.';
        _shouldResetDisplay = false;
      } else if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }

  // удаление последнего символа
  void _deleteLastChar() {
    setState(() {
      if (_display.length > 1 && _display != 'Error') {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
      }
      _shouldResetDisplay = false;
    });
  }

  // вычисление синуса (в градусах)
  void _calculateSin() {
    final number = double.tryParse(_display);
    if (number == null) return;

    try {
      // переводим градусы в радианы
      final radians = number * (math.pi / 180);
      final result = math.sin(radians);

      setState(() {
        if (result % 1 == 0) {
          _display = result.toInt().toString();
        } else {
      var temp = result.toStringAsFixed(10);
      temp = temp.replaceAll(RegExp(r'0+$'), '');
      temp = temp.replaceAll(RegExp(r'\.$'), '');
      _display = temp;
        }
        _shouldResetDisplay = true;
      });
    } catch (e) {
      setState(() {
        _display = 'Error';
        _shouldResetDisplay = true;
      });
    }
  }

  void _setOperation(String op) {
    if (_operation != null && !_shouldResetDisplay) {
      _calculate();
    } else {
      setState(() {
        _firstNumber = double.tryParse(_display);
        _operation = op;
        _shouldResetDisplay = true;
      });
    }
  }

  // основная функция вычисления
  void _calculate() {
    if (_operation == null || _firstNumber == null) return;

    final secondNumber = double.tryParse(_display);
    if (secondNumber == null) return;

    double? result;

    try {
      switch (_operation) {
        case '+':
          result = _firstNumber! + secondNumber;
          break;
        case '-':
          result = _firstNumber! - secondNumber;
          break;
        case '×':
          result = _firstNumber! * secondNumber;
          break;
        case '÷':
          // проверка деления на ноль
          if (secondNumber == 0) {
            setState(() {
              _display = 'Error';
              _operation = null;
              _firstNumber = null;
              _shouldResetDisplay = true;
            });
            return;
          }
          result = _firstNumber! / secondNumber;
          break;
        case '^':
          result = math.pow(_firstNumber!, secondNumber).toDouble();
          break;
      }

      if (result != null) {
        final finalResult = result;
        setState(() {
          // форматируем результат - убираем .0 если целое число
          if (finalResult % 1 == 0) {
            _display = finalResult.toInt().toString();
          } else {
            _display = finalResult.toString();
          }
          _operation = null;
          _firstNumber = null;
          _shouldResetDisplay = true;
        });
      }
    } catch (e) {
      setState(() {
        _display = 'Error';
        _operation = null;
        _firstNumber = null;
        _shouldResetDisplay = true;
      });
    }
  }

  // проверка что это цифра или точка
  bool _isNumberButton(String button) {
    if (button == '0' || button == '1' || button == '2' || button == '3' || 
        button == '4' || button == '5' || button == '6' || 
        button == '7' || button == '8' || button == '9' || button == '.') {
      return true;
    }
    return false;
  }

  bool _isOperationButton(String button) {
    if (button == '+' || button == '-' || button == '×' || button == '÷' || button == '^') {
      return true;
    }
    return false;
  }

  bool _isFunctionButton(String button) {
    return button == 'sin';
  }

  // получение цвета кнопки в зависимости от типа и темы
  Color _getButtonColor(String button) {
    final isPressed = _pressedButton == button;
    final isDark = widget.isDarkMode;

    if (button == 'C') {
      return isPressed
          ? (isDark ? Colors.red.shade700 : Colors.red.shade300)
          : (isDark ? Colors.red.shade800 : Colors.red.shade200);
    } else if (button == '⌫') {
      return isPressed
          ? (isDark ? Colors.purple.shade600 : Colors.purple.shade400)
          : (isDark ? Colors.purple.shade700 : Colors.purple.shade300);
    } else if (button == '=') {
      return isPressed
          ? (isDark ? Colors.blue.shade600 : Colors.blue.shade400)
          : (isDark ? Colors.blue.shade700 : Colors.blue.shade300);
    } else if (_isFunctionButton(button)) {
      return isPressed
          ? (isDark ? Colors.teal.shade600 : Colors.teal.shade400)
          : (isDark ? Colors.teal.shade700 : Colors.teal.shade300);
    } else if (_isNumberButton(button)) {
      return isPressed
          ? (isDark ? Colors.grey.shade700 : Colors.grey.shade400)
          : (isDark ? Colors.grey.shade800 : Colors.grey.shade200);
    } else if (_isOperationButton(button)) {
      return isPressed
          ? (isDark ? Colors.orange.shade600 : Colors.orange.shade400)
          : (isDark ? Colors.orange.shade700 : Colors.orange.shade300);
    }
    return isDark ? Colors.grey.shade800 : Colors.grey.shade200;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final backgroundColor = isDark ? Colors.grey.shade900 : Colors.grey.shade100;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // кнопка переключения темы справа вверху
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: widget.onThemeToggle,
                  icon: Icon(
                    isDark ? Icons.light_mode : Icons.dark_mode,
                    color: isDark ? Colors.amber : Colors.grey.shade700,
                    size: 28,
                  ),
                  tooltip: isDark ? 'Светлая тема' : 'Темная тема',
                ),
              ),
            ),
            // экран калькулятора
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                alignment: Alignment.bottomRight,
                child: Text(
                  _display,
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w300,
                    color: textColor,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // все кнопки
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // верхний ряд - функции
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton('C', flex: 1),
                          _buildButton('sin', flex: 1),
                          _buildButton('^', flex: 1),
                          _buildButton('⌫', flex: 1),
                        ],
                      ),
                    ),
                    // второй ряд - цифры слева, операции справа
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton('7', flex: 1),
                          _buildButton('8', flex: 1),
                          _buildButton('9', flex: 1),
                          _buildButton('÷', flex: 1),
                        ],
                      ),
                    ),
                    // третий ряд
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton('4', flex: 1),
                          _buildButton('5', flex: 1),
                          _buildButton('6', flex: 1),
                          _buildButton('×', flex: 1),
                        ],
                      ),
                    ),
                    // четвертый ряд
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton('1', flex: 1),
                          _buildButton('2', flex: 1),
                          _buildButton('3', flex: 1),
                          _buildButton('-', flex: 1),
                        ],
                      ),
                    ),
                    // пятый ряд
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton('0', flex: 2),
                          _buildButton('.', flex: 1),
                          _buildButton('+', flex: 1),
                        ],
                      ),
                    ),
                    // шестой ряд - кнопка равно на всю ширину
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton('=', flex: 4, isEquals: true),
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
    );
  }

  // создание кнопки (isEquals пока не используется, но оставлю на будущее)
  Widget _buildButton(String text, {int flex = 1, bool isEquals = false}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Material(
          color: _getButtonColor(text),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => _onButtonPressed(text),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              alignment: Alignment.center,
              child: text == '⌫'
                  ? Icon(
                      Icons.backspace,
                      size: 28,
                      color: Colors.white,
                    )
                  : Text(
                      text,
                      style: TextStyle(
                        fontSize: text == 'sin' ? 24 : 32,
                        fontWeight: FontWeight.w400,
                        color: text == 'C' ||
                                _isOperationButton(text) ||
                                text == '=' ||
                                text == '⌫' ||
                                _isFunctionButton(text)
                            ? Colors.white
                            : (widget.isDarkMode
                                ? Colors.white
                                : Colors.black87),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
