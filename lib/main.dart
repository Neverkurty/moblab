import 'package:flutter/material.dart';

void main() {
  runApp(const ConverterApp());
}

class ConverterApp extends StatelessWidget {
  const ConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Converter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.light,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

class ConversionCategory {
  const ConversionCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.units,
    this.customConverter,
  });

  final String id;
  final String title;
  final IconData icon;
  final List<ConverterUnit> units;
  final CustomConverter? customConverter;

  double convert(double value, ConverterUnit from, ConverterUnit to) {
    if (customConverter != null) {
      return customConverter!(value, from, to);
    }

    return value * from.factorToBase / to.factorToBase;
  }
}

typedef CustomConverter = double Function(
  double value,
  ConverterUnit from,
  ConverterUnit to,
);

class ConverterUnit {
  const ConverterUnit({
    required this.id,
    required this.label,
    required this.symbol,
    required this.factorToBase,
  });

  final String id;
  final String label;
  final String symbol;
  final double factorToBase;

  @override
  String toString() => label;
}

final _categories = <ConversionCategory>[
  ConversionCategory(
    id: 'length',
    title: 'Длина',
    icon: Icons.straighten,
    units: const [
      ConverterUnit(id: 'mm', label: 'Миллиметры', symbol: 'мм', factorToBase: 0.001),
      ConverterUnit(id: 'cm', label: 'Сантиметры', symbol: 'см', factorToBase: 0.01),
      ConverterUnit(id: 'm', label: 'Метры', symbol: 'м', factorToBase: 1),
      ConverterUnit(id: 'km', label: 'Километры', symbol: 'км', factorToBase: 1000),
      ConverterUnit(id: 'mi', label: 'Мили', symbol: 'mi', factorToBase: 1609.34),
    ],
  ),
  ConversionCategory(
    id: 'mass',
    title: 'Масса',
    icon: Icons.scale,
    units: const [
      ConverterUnit(id: 'g', label: 'Граммы', symbol: 'г', factorToBase: 0.001),
      ConverterUnit(id: 'kg', label: 'Килограммы', symbol: 'кг', factorToBase: 1),
      ConverterUnit(id: 'lb', label: 'Фунты', symbol: 'lb', factorToBase: 0.453592),
      ConverterUnit(id: 'oz', label: 'Унции', symbol: 'oz', factorToBase: 0.0283495),
    ],
  ),
  ConversionCategory(
    id: 'temperature',
    title: 'Температура',
    icon: Icons.thermostat,
    units: const [
      ConverterUnit(id: 'c', label: 'Цельсий', symbol: '°C', factorToBase: 1),
      ConverterUnit(id: 'f', label: 'Фаренгейт', symbol: '°F', factorToBase: 1),
      ConverterUnit(id: 'k', label: 'Кельвин', symbol: 'K', factorToBase: 1),
    ],
    customConverter: (value, from, to) {
      double toKelvin(double input, ConverterUnit unit) {
        switch (unit.id) {
          case 'c':
            return input + 273.15;
          case 'f':
            return (input - 32) * 5 / 9 + 273.15;
          case 'k':
            return input;
        }
        throw UnsupportedError('Неизвестная шкала');
      }

      double fromKelvin(double kelvin, ConverterUnit unit) {
        switch (unit.id) {
          case 'c':
            return kelvin - 273.15;
          case 'f':
            return (kelvin - 273.15) * 9 / 5 + 32;
          case 'k':
            return kelvin;
        }
        throw UnsupportedError('Неизвестная шкала');
      }

      final kelvin = toKelvin(value, from);
      return fromKelvin(kelvin, to);
    },
  ),
  ConversionCategory(
    id: 'currency',
    title: 'Валюта',
    icon: Icons.currency_exchange,
    units: const [
      ConverterUnit(id: 'rub', label: 'Рубли', symbol: '₽', factorToBase: 1),
      ConverterUnit(id: 'usd', label: 'Доллары', symbol: r'$', factorToBase: 92),
      ConverterUnit(id: 'eur', label: 'Евро', symbol: '€', factorToBase: 97),
      ConverterUnit(id: 'cny', label: 'Юани', symbol: '¥', factorToBase: 12.6),
    ],
  ),
  ConversionCategory(
    id: 'area',
    title: 'Площадь',
    icon: Icons.crop_square,
    units: const [
      ConverterUnit(id: 'sqm', label: 'Кв. метры', symbol: 'м²', factorToBase: 1),
      ConverterUnit(id: 'sqkm', label: 'Кв. километры', symbol: 'км²', factorToBase: 1e6),
      ConverterUnit(id: 'hectare', label: 'Гектары', symbol: 'га', factorToBase: 10000),
      ConverterUnit(id: 'sqft', label: 'Кв. футы', symbol: 'ft²', factorToBase: 0.092903),
    ],
  ),
  ConversionCategory(
    id: 'volume',
    title: 'Объём',
    icon: Icons.local_drink,
    units: const [
      ConverterUnit(id: 'ml', label: 'Миллилитры', symbol: 'мл', factorToBase: 0.001),
      ConverterUnit(id: 'l', label: 'Литры', symbol: 'л', factorToBase: 1),
      ConverterUnit(id: 'gal', label: 'Галлоны', symbol: 'gal', factorToBase: 3.78541),
      ConverterUnit(id: 'cup', label: 'Стаканы', symbol: 'cup', factorToBase: 0.24),
    ],
  ),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Converter'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _CategoryTile(category: category);
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: _categories.length,
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final ConversionCategory category;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConverterScreen(category: category),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(category.icon, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                category.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key, required this.category});

  final ConversionCategory category;

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  late ConverterUnit _fromUnit;
  late ConverterUnit _toUnit;
  String _input = '0';
  String? _error;

  @override
  void initState() {
    super.initState();
    _fromUnit = widget.category.units.first;
    _toUnit = widget.category.units[1];
  }

  void _appendSymbol(String symbol) {
    if (_error != null) {
      setState(() {
        _error = null;
      });
    }

    setState(() {
      switch (symbol) {
        case 'C':
          _input = '0';
          return;
        case '⌫':
          if (_input.length <= 1) {
            _input = '0';
          } else {
            _input = _input.substring(0, _input.length - 1);
          }
          return;
        case ',':
        case '.':
          if (_input.contains('.')) return;
          _input += '.';
          return;
        default:
          if (_input == '0') {
            _input = symbol;
          } else {
            _input += symbol;
          }
      }
    });
  }

  void _swapUnits() {
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
    });
  }

  double? _parseInput() {
    return double.tryParse(_input);
  }

  String _buildResult() {
    final value = _parseInput();
    if (value == null) {
      _error = 'Введите корректное число';
      return '—';
    }

    try {
      final converted = widget.category.convert(value, _fromUnit, _toUnit);
      return converted.toStringAsPrecision(6).replaceAll(RegExp(r'\.?0+$'), '');
    } catch (_) {
      _error = 'Операция недоступна';
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _buildResult();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _UnitPicker(
                  label: 'Откуда',
                  value: _fromUnit,
                  units: widget.category.units,
                  onChanged: (value) => setState(() => _fromUnit = value),
                ),
                const SizedBox(height: 12),
                _UnitPicker(
                  label: 'Куда',
                  value: _toUnit,
                  units: widget.category.units,
                  onChanged: (value) => setState(() => _toUnit = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _ValueCard(title: 'Ввод', value: '$_input ${_fromUnit.symbol}')),
                    IconButton(
                      onPressed: _swapUnits,
                      icon: const Icon(Icons.swap_vert, size: 28),
                      tooltip: 'Поменять местами',
                    ),
                    Expanded(child: _ValueCard(title: 'Результат', value: '$result ${_toUnit.symbol}')),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: _Keypad(onTap: _appendSymbol),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _UnitPicker extends StatelessWidget {
  const _UnitPicker({
    required this.label,
    required this.value,
    required this.units,
    required this.onChanged,
  });

  final String label;
  final ConverterUnit value;
  final List<ConverterUnit> units;
  final ValueChanged<ConverterUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ConverterUnit>(
              value: value,
              isExpanded: true,
              borderRadius: BorderRadius.circular(12),
              items: units
                  .map(
                    (unit) => DropdownMenuItem(
                      value: unit,
                      child: Text('${unit.label} (${unit.symbol})'),
                    ),
                  )
                  .toList(),
              onChanged: (unit) {
                if (unit != null) onChanged(unit);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.labelMedium),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    const buttons = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      ',',
      '0',
      '⌫',
    ];

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.25,
            ),
            itemCount: buttons.length,
            itemBuilder: (context, index) {
              final label = buttons[index];
              final isDestructive = label == '⌫';
              return _KeypadButton(
                label: label,
                isDestructive: isDestructive,
                onTap: () => onTap(label),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: () => onTap('C'),
            child: const Text('Очистить'),
          ),
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDestructive ? colorScheme.error : null,
        foregroundColor: isDestructive ? colorScheme.onError : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}
