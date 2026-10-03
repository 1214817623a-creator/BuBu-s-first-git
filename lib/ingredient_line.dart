import 'package:flutter/material.dart';
import 'models.dart';

/// Keep quantities compact; preparation notes occupy their own full-width line.
class IngredientLine extends StatelessWidget {
  final Ingredient ingredient;
  final int servings, base;
  const IngredientLine(this.ingredient, this.servings, this.base, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                ingredient.name,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              ingredient.quantity(servings, base),
              style: const TextStyle(color: Color(0xFF737D70)),
            ),
          ],
        ),
        if (ingredient.note.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            ingredient.note,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF737D70),
              height: 1.5,
            ),
          ),
        ],
      ],
    ),
  );
}
