// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $RecipesTable extends Recipes with TableInfo<$RecipesTable, Recipe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _servingsMeta = const VerificationMeta(
    'servings',
  );
  @override
  late final GeneratedColumn<int> servings = GeneratedColumn<int>(
    'servings',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [id, title, createdAt, servings];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Recipe> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('servings')) {
      context.handle(
        _servingsMeta,
        servings.isAcceptableOrUnknown(data['servings']!, _servingsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Recipe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Recipe(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      servings: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}servings'],
      )!,
    );
  }

  @override
  $RecipesTable createAlias(String alias) {
    return $RecipesTable(attachedDatabase, alias);
  }
}

class Recipe extends DataClass implements Insertable<Recipe> {
  final int id;
  final String title;
  final DateTime createdAt;
  final int servings;
  const Recipe({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.servings,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['servings'] = Variable<int>(servings);
    return map;
  }

  RecipesCompanion toCompanion(bool nullToAbsent) {
    return RecipesCompanion(
      id: Value(id),
      title: Value(title),
      createdAt: Value(createdAt),
      servings: Value(servings),
    );
  }

  factory Recipe.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Recipe(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      servings: serializer.fromJson<int>(json['servings']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'servings': serializer.toJson<int>(servings),
    };
  }

  Recipe copyWith({
    int? id,
    String? title,
    DateTime? createdAt,
    int? servings,
  }) => Recipe(
    id: id ?? this.id,
    title: title ?? this.title,
    createdAt: createdAt ?? this.createdAt,
    servings: servings ?? this.servings,
  );
  Recipe copyWithCompanion(RecipesCompanion data) {
    return Recipe(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      servings: data.servings.present ? data.servings.value : this.servings,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Recipe(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('servings: $servings')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, createdAt, servings);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Recipe &&
          other.id == this.id &&
          other.title == this.title &&
          other.createdAt == this.createdAt &&
          other.servings == this.servings);
}

class RecipesCompanion extends UpdateCompanion<Recipe> {
  final Value<int> id;
  final Value<String> title;
  final Value<DateTime> createdAt;
  final Value<int> servings;
  const RecipesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.servings = const Value.absent(),
  });
  RecipesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.createdAt = const Value.absent(),
    this.servings = const Value.absent(),
  }) : title = Value(title);
  static Insertable<Recipe> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<DateTime>? createdAt,
    Expression<int>? servings,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (createdAt != null) 'created_at': createdAt,
      if (servings != null) 'servings': servings,
    });
  }

  RecipesCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<DateTime>? createdAt,
    Value<int>? servings,
  }) {
    return RecipesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      servings: servings ?? this.servings,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (servings.present) {
      map['servings'] = Variable<int>(servings.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('servings: $servings')
          ..write(')'))
        .toString();
  }
}

class $RecipeIngredientsTable extends RecipeIngredients
    with TableInfo<$RecipeIngredientsTable, RecipeIngredient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeIngredientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<int> recipeId = GeneratedColumn<int>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recipes (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<String> quantity = GeneratedColumn<String>(
    'quantity',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, recipeId, name, quantity, unit];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_ingredients';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeIngredient> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecipeIngredient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeIngredient(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recipe_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quantity'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
    );
  }

  @override
  $RecipeIngredientsTable createAlias(String alias) {
    return $RecipeIngredientsTable(attachedDatabase, alias);
  }
}

class RecipeIngredient extends DataClass
    implements Insertable<RecipeIngredient> {
  final int id;
  final int recipeId;
  final String name;
  final String? quantity;
  final String? unit;
  const RecipeIngredient({
    required this.id,
    required this.recipeId,
    required this.name,
    this.quantity,
    this.unit,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['recipe_id'] = Variable<int>(recipeId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<String>(quantity);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    return map;
  }

  RecipeIngredientsCompanion toCompanion(bool nullToAbsent) {
    return RecipeIngredientsCompanion(
      id: Value(id),
      recipeId: Value(recipeId),
      name: Value(name),
      quantity: quantity == null && nullToAbsent
          ? const Value.absent()
          : Value(quantity),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
    );
  }

  factory RecipeIngredient.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeIngredient(
      id: serializer.fromJson<int>(json['id']),
      recipeId: serializer.fromJson<int>(json['recipeId']),
      name: serializer.fromJson<String>(json['name']),
      quantity: serializer.fromJson<String?>(json['quantity']),
      unit: serializer.fromJson<String?>(json['unit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recipeId': serializer.toJson<int>(recipeId),
      'name': serializer.toJson<String>(name),
      'quantity': serializer.toJson<String?>(quantity),
      'unit': serializer.toJson<String?>(unit),
    };
  }

  RecipeIngredient copyWith({
    int? id,
    int? recipeId,
    String? name,
    Value<String?> quantity = const Value.absent(),
    Value<String?> unit = const Value.absent(),
  }) => RecipeIngredient(
    id: id ?? this.id,
    recipeId: recipeId ?? this.recipeId,
    name: name ?? this.name,
    quantity: quantity.present ? quantity.value : this.quantity,
    unit: unit.present ? unit.value : this.unit,
  );
  RecipeIngredient copyWithCompanion(RecipeIngredientsCompanion data) {
    return RecipeIngredient(
      id: data.id.present ? data.id.value : this.id,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      name: data.name.present ? data.name.value : this.name,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeIngredient(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, recipeId, name, quantity, unit);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeIngredient &&
          other.id == this.id &&
          other.recipeId == this.recipeId &&
          other.name == this.name &&
          other.quantity == this.quantity &&
          other.unit == this.unit);
}

class RecipeIngredientsCompanion extends UpdateCompanion<RecipeIngredient> {
  final Value<int> id;
  final Value<int> recipeId;
  final Value<String> name;
  final Value<String?> quantity;
  final Value<String?> unit;
  const RecipeIngredientsCompanion({
    this.id = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.name = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
  });
  RecipeIngredientsCompanion.insert({
    this.id = const Value.absent(),
    required int recipeId,
    required String name,
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
  }) : recipeId = Value(recipeId),
       name = Value(name);
  static Insertable<RecipeIngredient> custom({
    Expression<int>? id,
    Expression<int>? recipeId,
    Expression<String>? name,
    Expression<String>? quantity,
    Expression<String>? unit,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipeId != null) 'recipe_id': recipeId,
      if (name != null) 'name': name,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
    });
  }

  RecipeIngredientsCompanion copyWith({
    Value<int>? id,
    Value<int>? recipeId,
    Value<String>? name,
    Value<String?>? quantity,
    Value<String?>? unit,
  }) {
    return RecipeIngredientsCompanion(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<int>(recipeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<String>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeIngredientsCompanion(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit')
          ..write(')'))
        .toString();
  }
}

class $RecipeStepsTable extends RecipeSteps
    with TableInfo<$RecipeStepsTable, RecipeStep> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeStepsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<int> recipeId = GeneratedColumn<int>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recipes (id)',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepTextMeta = const VerificationMeta(
    'stepText',
  );
  @override
  late final GeneratedColumn<String> stepText = GeneratedColumn<String>(
    'step_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, recipeId, position, stepText];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_steps';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeStep> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('step_text')) {
      context.handle(
        _stepTextMeta,
        stepText.isAcceptableOrUnknown(data['step_text']!, _stepTextMeta),
      );
    } else if (isInserting) {
      context.missing(_stepTextMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecipeStep map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeStep(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recipe_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      stepText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}step_text'],
      )!,
    );
  }

  @override
  $RecipeStepsTable createAlias(String alias) {
    return $RecipeStepsTable(attachedDatabase, alias);
  }
}

class RecipeStep extends DataClass implements Insertable<RecipeStep> {
  final int id;
  final int recipeId;
  final int position;
  final String stepText;
  const RecipeStep({
    required this.id,
    required this.recipeId,
    required this.position,
    required this.stepText,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['recipe_id'] = Variable<int>(recipeId);
    map['position'] = Variable<int>(position);
    map['step_text'] = Variable<String>(stepText);
    return map;
  }

  RecipeStepsCompanion toCompanion(bool nullToAbsent) {
    return RecipeStepsCompanion(
      id: Value(id),
      recipeId: Value(recipeId),
      position: Value(position),
      stepText: Value(stepText),
    );
  }

  factory RecipeStep.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeStep(
      id: serializer.fromJson<int>(json['id']),
      recipeId: serializer.fromJson<int>(json['recipeId']),
      position: serializer.fromJson<int>(json['position']),
      stepText: serializer.fromJson<String>(json['stepText']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recipeId': serializer.toJson<int>(recipeId),
      'position': serializer.toJson<int>(position),
      'stepText': serializer.toJson<String>(stepText),
    };
  }

  RecipeStep copyWith({
    int? id,
    int? recipeId,
    int? position,
    String? stepText,
  }) => RecipeStep(
    id: id ?? this.id,
    recipeId: recipeId ?? this.recipeId,
    position: position ?? this.position,
    stepText: stepText ?? this.stepText,
  );
  RecipeStep copyWithCompanion(RecipeStepsCompanion data) {
    return RecipeStep(
      id: data.id.present ? data.id.value : this.id,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      position: data.position.present ? data.position.value : this.position,
      stepText: data.stepText.present ? data.stepText.value : this.stepText,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeStep(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('position: $position, ')
          ..write('stepText: $stepText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, recipeId, position, stepText);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeStep &&
          other.id == this.id &&
          other.recipeId == this.recipeId &&
          other.position == this.position &&
          other.stepText == this.stepText);
}

class RecipeStepsCompanion extends UpdateCompanion<RecipeStep> {
  final Value<int> id;
  final Value<int> recipeId;
  final Value<int> position;
  final Value<String> stepText;
  const RecipeStepsCompanion({
    this.id = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.position = const Value.absent(),
    this.stepText = const Value.absent(),
  });
  RecipeStepsCompanion.insert({
    this.id = const Value.absent(),
    required int recipeId,
    required int position,
    required String stepText,
  }) : recipeId = Value(recipeId),
       position = Value(position),
       stepText = Value(stepText);
  static Insertable<RecipeStep> custom({
    Expression<int>? id,
    Expression<int>? recipeId,
    Expression<int>? position,
    Expression<String>? stepText,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipeId != null) 'recipe_id': recipeId,
      if (position != null) 'position': position,
      if (stepText != null) 'step_text': stepText,
    });
  }

  RecipeStepsCompanion copyWith({
    Value<int>? id,
    Value<int>? recipeId,
    Value<int>? position,
    Value<String>? stepText,
  }) {
    return RecipeStepsCompanion(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      position: position ?? this.position,
      stepText: stepText ?? this.stepText,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<int>(recipeId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (stepText.present) {
      map['step_text'] = Variable<String>(stepText.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeStepsCompanion(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('position: $position, ')
          ..write('stepText: $stepText')
          ..write(')'))
        .toString();
  }
}

class $RecipeNutritionCacheTable extends RecipeNutritionCache
    with TableInfo<$RecipeNutritionCacheTable, RecipeNutritionCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeNutritionCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<int> recipeId = GeneratedColumn<int>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recipes (id)',
    ),
  );
  static const VerificationMeta _ingredientsHashMeta = const VerificationMeta(
    'ingredientsHash',
  );
  @override
  late final GeneratedColumn<String> ingredientsHash = GeneratedColumn<String>(
    'ingredients_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _breakdownJsonMeta = const VerificationMeta(
    'breakdownJson',
  );
  @override
  late final GeneratedColumn<String> breakdownJson = GeneratedColumn<String>(
    'breakdown_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    recipeId,
    ingredientsHash,
    breakdownJson,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_nutrition_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeNutritionCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    }
    if (data.containsKey('ingredients_hash')) {
      context.handle(
        _ingredientsHashMeta,
        ingredientsHash.isAcceptableOrUnknown(
          data['ingredients_hash']!,
          _ingredientsHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ingredientsHashMeta);
    }
    if (data.containsKey('breakdown_json')) {
      context.handle(
        _breakdownJsonMeta,
        breakdownJson.isAcceptableOrUnknown(
          data['breakdown_json']!,
          _breakdownJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_breakdownJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recipeId};
  @override
  RecipeNutritionCacheData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeNutritionCacheData(
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recipe_id'],
      )!,
      ingredientsHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ingredients_hash'],
      )!,
      breakdownJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}breakdown_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RecipeNutritionCacheTable createAlias(String alias) {
    return $RecipeNutritionCacheTable(attachedDatabase, alias);
  }
}

class RecipeNutritionCacheData extends DataClass
    implements Insertable<RecipeNutritionCacheData> {
  final int recipeId;

  /// Signature of the ingredient list this breakdown was computed from; a
  /// mismatch against the recipe's current ingredients forces a recompute.
  final String ingredientsHash;

  /// Serialized [RecipeBreakdown] (per-ingredient macros + source + totals).
  final String breakdownJson;
  final DateTime updatedAt;
  const RecipeNutritionCacheData({
    required this.recipeId,
    required this.ingredientsHash,
    required this.breakdownJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['recipe_id'] = Variable<int>(recipeId);
    map['ingredients_hash'] = Variable<String>(ingredientsHash);
    map['breakdown_json'] = Variable<String>(breakdownJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RecipeNutritionCacheCompanion toCompanion(bool nullToAbsent) {
    return RecipeNutritionCacheCompanion(
      recipeId: Value(recipeId),
      ingredientsHash: Value(ingredientsHash),
      breakdownJson: Value(breakdownJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory RecipeNutritionCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeNutritionCacheData(
      recipeId: serializer.fromJson<int>(json['recipeId']),
      ingredientsHash: serializer.fromJson<String>(json['ingredientsHash']),
      breakdownJson: serializer.fromJson<String>(json['breakdownJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recipeId': serializer.toJson<int>(recipeId),
      'ingredientsHash': serializer.toJson<String>(ingredientsHash),
      'breakdownJson': serializer.toJson<String>(breakdownJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RecipeNutritionCacheData copyWith({
    int? recipeId,
    String? ingredientsHash,
    String? breakdownJson,
    DateTime? updatedAt,
  }) => RecipeNutritionCacheData(
    recipeId: recipeId ?? this.recipeId,
    ingredientsHash: ingredientsHash ?? this.ingredientsHash,
    breakdownJson: breakdownJson ?? this.breakdownJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RecipeNutritionCacheData copyWithCompanion(
    RecipeNutritionCacheCompanion data,
  ) {
    return RecipeNutritionCacheData(
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      ingredientsHash: data.ingredientsHash.present
          ? data.ingredientsHash.value
          : this.ingredientsHash,
      breakdownJson: data.breakdownJson.present
          ? data.breakdownJson.value
          : this.breakdownJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeNutritionCacheData(')
          ..write('recipeId: $recipeId, ')
          ..write('ingredientsHash: $ingredientsHash, ')
          ..write('breakdownJson: $breakdownJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(recipeId, ingredientsHash, breakdownJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeNutritionCacheData &&
          other.recipeId == this.recipeId &&
          other.ingredientsHash == this.ingredientsHash &&
          other.breakdownJson == this.breakdownJson &&
          other.updatedAt == this.updatedAt);
}

class RecipeNutritionCacheCompanion
    extends UpdateCompanion<RecipeNutritionCacheData> {
  final Value<int> recipeId;
  final Value<String> ingredientsHash;
  final Value<String> breakdownJson;
  final Value<DateTime> updatedAt;
  const RecipeNutritionCacheCompanion({
    this.recipeId = const Value.absent(),
    this.ingredientsHash = const Value.absent(),
    this.breakdownJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  RecipeNutritionCacheCompanion.insert({
    this.recipeId = const Value.absent(),
    required String ingredientsHash,
    required String breakdownJson,
    this.updatedAt = const Value.absent(),
  }) : ingredientsHash = Value(ingredientsHash),
       breakdownJson = Value(breakdownJson);
  static Insertable<RecipeNutritionCacheData> custom({
    Expression<int>? recipeId,
    Expression<String>? ingredientsHash,
    Expression<String>? breakdownJson,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (recipeId != null) 'recipe_id': recipeId,
      if (ingredientsHash != null) 'ingredients_hash': ingredientsHash,
      if (breakdownJson != null) 'breakdown_json': breakdownJson,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  RecipeNutritionCacheCompanion copyWith({
    Value<int>? recipeId,
    Value<String>? ingredientsHash,
    Value<String>? breakdownJson,
    Value<DateTime>? updatedAt,
  }) {
    return RecipeNutritionCacheCompanion(
      recipeId: recipeId ?? this.recipeId,
      ingredientsHash: ingredientsHash ?? this.ingredientsHash,
      breakdownJson: breakdownJson ?? this.breakdownJson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recipeId.present) {
      map['recipe_id'] = Variable<int>(recipeId.value);
    }
    if (ingredientsHash.present) {
      map['ingredients_hash'] = Variable<String>(ingredientsHash.value);
    }
    if (breakdownJson.present) {
      map['breakdown_json'] = Variable<String>(breakdownJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeNutritionCacheCompanion(')
          ..write('recipeId: $recipeId, ')
          ..write('ingredientsHash: $ingredientsHash, ')
          ..write('breakdownJson: $breakdownJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $FoodCacheTable extends FoodCache
    with TableInfo<$FoodCacheTable, FoodCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kcal100Meta = const VerificationMeta(
    'kcal100',
  );
  @override
  late final GeneratedColumn<double> kcal100 = GeneratedColumn<double>(
    'kcal100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _protein100Meta = const VerificationMeta(
    'protein100',
  );
  @override
  late final GeneratedColumn<double> protein100 = GeneratedColumn<double>(
    'protein100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carb100Meta = const VerificationMeta(
    'carb100',
  );
  @override
  late final GeneratedColumn<double> carb100 = GeneratedColumn<double>(
    'carb100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fat100Meta = const VerificationMeta('fat100');
  @override
  late final GeneratedColumn<double> fat100 = GeneratedColumn<double>(
    'fat100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isEstimateMeta = const VerificationMeta(
    'isEstimate',
  );
  @override
  late final GeneratedColumn<bool> isEstimate = GeneratedColumn<bool>(
    'is_estimate',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_estimate" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _userOverrideMeta = const VerificationMeta(
    'userOverride',
  );
  @override
  late final GeneratedColumn<bool> userOverride = GeneratedColumn<bool>(
    'user_override',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("user_override" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _gramsPerPieceMeta = const VerificationMeta(
    'gramsPerPiece',
  );
  @override
  late final GeneratedColumn<double> gramsPerPiece = GeneratedColumn<double>(
    'grams_per_piece',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fibre100Meta = const VerificationMeta(
    'fibre100',
  );
  @override
  late final GeneratedColumn<double> fibre100 = GeneratedColumn<double>(
    'fibre100',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sodium100Meta = const VerificationMeta(
    'sodium100',
  );
  @override
  late final GeneratedColumn<double> sodium100 = GeneratedColumn<double>(
    'sodium100',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _basisQuantityMeta = const VerificationMeta(
    'basisQuantity',
  );
  @override
  late final GeneratedColumn<double> basisQuantity = GeneratedColumn<double>(
    'basis_quantity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _basisUnitMeta = const VerificationMeta(
    'basisUnit',
  );
  @override
  late final GeneratedColumn<String> basisUnit = GeneratedColumn<String>(
    'basis_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _basisKcalMeta = const VerificationMeta(
    'basisKcal',
  );
  @override
  late final GeneratedColumn<double> basisKcal = GeneratedColumn<double>(
    'basis_kcal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _basisProteinMeta = const VerificationMeta(
    'basisProtein',
  );
  @override
  late final GeneratedColumn<double> basisProtein = GeneratedColumn<double>(
    'basis_protein',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _basisCarbMeta = const VerificationMeta(
    'basisCarb',
  );
  @override
  late final GeneratedColumn<double> basisCarb = GeneratedColumn<double>(
    'basis_carb',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _basisFatMeta = const VerificationMeta(
    'basisFat',
  );
  @override
  late final GeneratedColumn<double> basisFat = GeneratedColumn<double>(
    'basis_fat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _basisPhysicalGramsMeta =
      const VerificationMeta('basisPhysicalGrams');
  @override
  late final GeneratedColumn<double> basisPhysicalGrams =
      GeneratedColumn<double>(
        'basis_physical_grams',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _basisNeedsReviewMeta = const VerificationMeta(
    'basisNeedsReview',
  );
  @override
  late final GeneratedColumn<bool> basisNeedsReview = GeneratedColumn<bool>(
    'basis_needs_review',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("basis_needs_review" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceTitleMeta = const VerificationMeta(
    'sourceTitle',
  );
  @override
  late final GeneratedColumn<String> sourceTitle = GeneratedColumn<String>(
    'source_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceRetrievedAtMeta = const VerificationMeta(
    'sourceRetrievedAt',
  );
  @override
  late final GeneratedColumn<DateTime> sourceRetrievedAt =
      GeneratedColumn<DateTime>(
        'source_retrieved_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sourceInferredFieldsMeta =
      const VerificationMeta('sourceInferredFields');
  @override
  late final GeneratedColumn<String> sourceInferredFields =
      GeneratedColumn<String>(
        'source_inferred_fields',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    source,
    kcal100,
    protein100,
    carb100,
    fat100,
    isEstimate,
    userOverride,
    gramsPerPiece,
    fibre100,
    sodium100,
    basisQuantity,
    basisUnit,
    basisKcal,
    basisProtein,
    basisCarb,
    basisFat,
    basisPhysicalGrams,
    basisNeedsReview,
    sourceUrl,
    sourceTitle,
    sourceRetrievedAt,
    sourceInferredFields,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('kcal100')) {
      context.handle(
        _kcal100Meta,
        kcal100.isAcceptableOrUnknown(data['kcal100']!, _kcal100Meta),
      );
    } else if (isInserting) {
      context.missing(_kcal100Meta);
    }
    if (data.containsKey('protein100')) {
      context.handle(
        _protein100Meta,
        protein100.isAcceptableOrUnknown(data['protein100']!, _protein100Meta),
      );
    } else if (isInserting) {
      context.missing(_protein100Meta);
    }
    if (data.containsKey('carb100')) {
      context.handle(
        _carb100Meta,
        carb100.isAcceptableOrUnknown(data['carb100']!, _carb100Meta),
      );
    } else if (isInserting) {
      context.missing(_carb100Meta);
    }
    if (data.containsKey('fat100')) {
      context.handle(
        _fat100Meta,
        fat100.isAcceptableOrUnknown(data['fat100']!, _fat100Meta),
      );
    } else if (isInserting) {
      context.missing(_fat100Meta);
    }
    if (data.containsKey('is_estimate')) {
      context.handle(
        _isEstimateMeta,
        isEstimate.isAcceptableOrUnknown(data['is_estimate']!, _isEstimateMeta),
      );
    }
    if (data.containsKey('user_override')) {
      context.handle(
        _userOverrideMeta,
        userOverride.isAcceptableOrUnknown(
          data['user_override']!,
          _userOverrideMeta,
        ),
      );
    }
    if (data.containsKey('grams_per_piece')) {
      context.handle(
        _gramsPerPieceMeta,
        gramsPerPiece.isAcceptableOrUnknown(
          data['grams_per_piece']!,
          _gramsPerPieceMeta,
        ),
      );
    }
    if (data.containsKey('fibre100')) {
      context.handle(
        _fibre100Meta,
        fibre100.isAcceptableOrUnknown(data['fibre100']!, _fibre100Meta),
      );
    }
    if (data.containsKey('sodium100')) {
      context.handle(
        _sodium100Meta,
        sodium100.isAcceptableOrUnknown(data['sodium100']!, _sodium100Meta),
      );
    }
    if (data.containsKey('basis_quantity')) {
      context.handle(
        _basisQuantityMeta,
        basisQuantity.isAcceptableOrUnknown(
          data['basis_quantity']!,
          _basisQuantityMeta,
        ),
      );
    }
    if (data.containsKey('basis_unit')) {
      context.handle(
        _basisUnitMeta,
        basisUnit.isAcceptableOrUnknown(data['basis_unit']!, _basisUnitMeta),
      );
    }
    if (data.containsKey('basis_kcal')) {
      context.handle(
        _basisKcalMeta,
        basisKcal.isAcceptableOrUnknown(data['basis_kcal']!, _basisKcalMeta),
      );
    }
    if (data.containsKey('basis_protein')) {
      context.handle(
        _basisProteinMeta,
        basisProtein.isAcceptableOrUnknown(
          data['basis_protein']!,
          _basisProteinMeta,
        ),
      );
    }
    if (data.containsKey('basis_carb')) {
      context.handle(
        _basisCarbMeta,
        basisCarb.isAcceptableOrUnknown(data['basis_carb']!, _basisCarbMeta),
      );
    }
    if (data.containsKey('basis_fat')) {
      context.handle(
        _basisFatMeta,
        basisFat.isAcceptableOrUnknown(data['basis_fat']!, _basisFatMeta),
      );
    }
    if (data.containsKey('basis_physical_grams')) {
      context.handle(
        _basisPhysicalGramsMeta,
        basisPhysicalGrams.isAcceptableOrUnknown(
          data['basis_physical_grams']!,
          _basisPhysicalGramsMeta,
        ),
      );
    }
    if (data.containsKey('basis_needs_review')) {
      context.handle(
        _basisNeedsReviewMeta,
        basisNeedsReview.isAcceptableOrUnknown(
          data['basis_needs_review']!,
          _basisNeedsReviewMeta,
        ),
      );
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    }
    if (data.containsKey('source_title')) {
      context.handle(
        _sourceTitleMeta,
        sourceTitle.isAcceptableOrUnknown(
          data['source_title']!,
          _sourceTitleMeta,
        ),
      );
    }
    if (data.containsKey('source_retrieved_at')) {
      context.handle(
        _sourceRetrievedAtMeta,
        sourceRetrievedAt.isAcceptableOrUnknown(
          data['source_retrieved_at']!,
          _sourceRetrievedAtMeta,
        ),
      );
    }
    if (data.containsKey('source_inferred_fields')) {
      context.handle(
        _sourceInferredFieldsMeta,
        sourceInferredFields.isAcceptableOrUnknown(
          data['source_inferred_fields']!,
          _sourceInferredFieldsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FoodCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodCacheData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      kcal100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal100'],
      )!,
      protein100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein100'],
      )!,
      carb100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carb100'],
      )!,
      fat100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat100'],
      )!,
      isEstimate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_estimate'],
      )!,
      userOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}user_override'],
      )!,
      gramsPerPiece: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams_per_piece'],
      ),
      fibre100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fibre100'],
      ),
      sodium100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sodium100'],
      ),
      basisQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}basis_quantity'],
      ),
      basisUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}basis_unit'],
      ),
      basisKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}basis_kcal'],
      ),
      basisProtein: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}basis_protein'],
      ),
      basisCarb: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}basis_carb'],
      ),
      basisFat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}basis_fat'],
      ),
      basisPhysicalGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}basis_physical_grams'],
      ),
      basisNeedsReview: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}basis_needs_review'],
      )!,
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      ),
      sourceTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_title'],
      ),
      sourceRetrievedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}source_retrieved_at'],
      ),
      sourceInferredFields: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_inferred_fields'],
      ),
    );
  }

  @override
  $FoodCacheTable createAlias(String alias) {
    return $FoodCacheTable(attachedDatabase, alias);
  }
}

class FoodCacheData extends DataClass implements Insertable<FoodCacheData> {
  final int id;
  final String name;
  final String source;
  final double kcal100;
  final double protein100;
  final double carb100;
  final double fat100;
  final bool isEstimate;
  final bool userOverride;
  final double? gramsPerPiece;
  final double? fibre100;
  final double? sodium100;
  final double? basisQuantity;
  final String? basisUnit;
  final double? basisKcal;
  final double? basisProtein;
  final double? basisCarb;
  final double? basisFat;
  final double? basisPhysicalGrams;
  final bool basisNeedsReview;
  final String? sourceUrl;
  final String? sourceTitle;
  final DateTime? sourceRetrievedAt;
  final String? sourceInferredFields;
  const FoodCacheData({
    required this.id,
    required this.name,
    required this.source,
    required this.kcal100,
    required this.protein100,
    required this.carb100,
    required this.fat100,
    required this.isEstimate,
    required this.userOverride,
    this.gramsPerPiece,
    this.fibre100,
    this.sodium100,
    this.basisQuantity,
    this.basisUnit,
    this.basisKcal,
    this.basisProtein,
    this.basisCarb,
    this.basisFat,
    this.basisPhysicalGrams,
    required this.basisNeedsReview,
    this.sourceUrl,
    this.sourceTitle,
    this.sourceRetrievedAt,
    this.sourceInferredFields,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['source'] = Variable<String>(source);
    map['kcal100'] = Variable<double>(kcal100);
    map['protein100'] = Variable<double>(protein100);
    map['carb100'] = Variable<double>(carb100);
    map['fat100'] = Variable<double>(fat100);
    map['is_estimate'] = Variable<bool>(isEstimate);
    map['user_override'] = Variable<bool>(userOverride);
    if (!nullToAbsent || gramsPerPiece != null) {
      map['grams_per_piece'] = Variable<double>(gramsPerPiece);
    }
    if (!nullToAbsent || fibre100 != null) {
      map['fibre100'] = Variable<double>(fibre100);
    }
    if (!nullToAbsent || sodium100 != null) {
      map['sodium100'] = Variable<double>(sodium100);
    }
    if (!nullToAbsent || basisQuantity != null) {
      map['basis_quantity'] = Variable<double>(basisQuantity);
    }
    if (!nullToAbsent || basisUnit != null) {
      map['basis_unit'] = Variable<String>(basisUnit);
    }
    if (!nullToAbsent || basisKcal != null) {
      map['basis_kcal'] = Variable<double>(basisKcal);
    }
    if (!nullToAbsent || basisProtein != null) {
      map['basis_protein'] = Variable<double>(basisProtein);
    }
    if (!nullToAbsent || basisCarb != null) {
      map['basis_carb'] = Variable<double>(basisCarb);
    }
    if (!nullToAbsent || basisFat != null) {
      map['basis_fat'] = Variable<double>(basisFat);
    }
    if (!nullToAbsent || basisPhysicalGrams != null) {
      map['basis_physical_grams'] = Variable<double>(basisPhysicalGrams);
    }
    map['basis_needs_review'] = Variable<bool>(basisNeedsReview);
    if (!nullToAbsent || sourceUrl != null) {
      map['source_url'] = Variable<String>(sourceUrl);
    }
    if (!nullToAbsent || sourceTitle != null) {
      map['source_title'] = Variable<String>(sourceTitle);
    }
    if (!nullToAbsent || sourceRetrievedAt != null) {
      map['source_retrieved_at'] = Variable<DateTime>(sourceRetrievedAt);
    }
    if (!nullToAbsent || sourceInferredFields != null) {
      map['source_inferred_fields'] = Variable<String>(sourceInferredFields);
    }
    return map;
  }

  FoodCacheCompanion toCompanion(bool nullToAbsent) {
    return FoodCacheCompanion(
      id: Value(id),
      name: Value(name),
      source: Value(source),
      kcal100: Value(kcal100),
      protein100: Value(protein100),
      carb100: Value(carb100),
      fat100: Value(fat100),
      isEstimate: Value(isEstimate),
      userOverride: Value(userOverride),
      gramsPerPiece: gramsPerPiece == null && nullToAbsent
          ? const Value.absent()
          : Value(gramsPerPiece),
      fibre100: fibre100 == null && nullToAbsent
          ? const Value.absent()
          : Value(fibre100),
      sodium100: sodium100 == null && nullToAbsent
          ? const Value.absent()
          : Value(sodium100),
      basisQuantity: basisQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(basisQuantity),
      basisUnit: basisUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(basisUnit),
      basisKcal: basisKcal == null && nullToAbsent
          ? const Value.absent()
          : Value(basisKcal),
      basisProtein: basisProtein == null && nullToAbsent
          ? const Value.absent()
          : Value(basisProtein),
      basisCarb: basisCarb == null && nullToAbsent
          ? const Value.absent()
          : Value(basisCarb),
      basisFat: basisFat == null && nullToAbsent
          ? const Value.absent()
          : Value(basisFat),
      basisPhysicalGrams: basisPhysicalGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(basisPhysicalGrams),
      basisNeedsReview: Value(basisNeedsReview),
      sourceUrl: sourceUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUrl),
      sourceTitle: sourceTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceTitle),
      sourceRetrievedAt: sourceRetrievedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceRetrievedAt),
      sourceInferredFields: sourceInferredFields == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceInferredFields),
    );
  }

  factory FoodCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodCacheData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      source: serializer.fromJson<String>(json['source']),
      kcal100: serializer.fromJson<double>(json['kcal100']),
      protein100: serializer.fromJson<double>(json['protein100']),
      carb100: serializer.fromJson<double>(json['carb100']),
      fat100: serializer.fromJson<double>(json['fat100']),
      isEstimate: serializer.fromJson<bool>(json['isEstimate']),
      userOverride: serializer.fromJson<bool>(json['userOverride']),
      gramsPerPiece: serializer.fromJson<double?>(json['gramsPerPiece']),
      fibre100: serializer.fromJson<double?>(json['fibre100']),
      sodium100: serializer.fromJson<double?>(json['sodium100']),
      basisQuantity: serializer.fromJson<double?>(json['basisQuantity']),
      basisUnit: serializer.fromJson<String?>(json['basisUnit']),
      basisKcal: serializer.fromJson<double?>(json['basisKcal']),
      basisProtein: serializer.fromJson<double?>(json['basisProtein']),
      basisCarb: serializer.fromJson<double?>(json['basisCarb']),
      basisFat: serializer.fromJson<double?>(json['basisFat']),
      basisPhysicalGrams: serializer.fromJson<double?>(
        json['basisPhysicalGrams'],
      ),
      basisNeedsReview: serializer.fromJson<bool>(json['basisNeedsReview']),
      sourceUrl: serializer.fromJson<String?>(json['sourceUrl']),
      sourceTitle: serializer.fromJson<String?>(json['sourceTitle']),
      sourceRetrievedAt: serializer.fromJson<DateTime?>(
        json['sourceRetrievedAt'],
      ),
      sourceInferredFields: serializer.fromJson<String?>(
        json['sourceInferredFields'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'source': serializer.toJson<String>(source),
      'kcal100': serializer.toJson<double>(kcal100),
      'protein100': serializer.toJson<double>(protein100),
      'carb100': serializer.toJson<double>(carb100),
      'fat100': serializer.toJson<double>(fat100),
      'isEstimate': serializer.toJson<bool>(isEstimate),
      'userOverride': serializer.toJson<bool>(userOverride),
      'gramsPerPiece': serializer.toJson<double?>(gramsPerPiece),
      'fibre100': serializer.toJson<double?>(fibre100),
      'sodium100': serializer.toJson<double?>(sodium100),
      'basisQuantity': serializer.toJson<double?>(basisQuantity),
      'basisUnit': serializer.toJson<String?>(basisUnit),
      'basisKcal': serializer.toJson<double?>(basisKcal),
      'basisProtein': serializer.toJson<double?>(basisProtein),
      'basisCarb': serializer.toJson<double?>(basisCarb),
      'basisFat': serializer.toJson<double?>(basisFat),
      'basisPhysicalGrams': serializer.toJson<double?>(basisPhysicalGrams),
      'basisNeedsReview': serializer.toJson<bool>(basisNeedsReview),
      'sourceUrl': serializer.toJson<String?>(sourceUrl),
      'sourceTitle': serializer.toJson<String?>(sourceTitle),
      'sourceRetrievedAt': serializer.toJson<DateTime?>(sourceRetrievedAt),
      'sourceInferredFields': serializer.toJson<String?>(sourceInferredFields),
    };
  }

  FoodCacheData copyWith({
    int? id,
    String? name,
    String? source,
    double? kcal100,
    double? protein100,
    double? carb100,
    double? fat100,
    bool? isEstimate,
    bool? userOverride,
    Value<double?> gramsPerPiece = const Value.absent(),
    Value<double?> fibre100 = const Value.absent(),
    Value<double?> sodium100 = const Value.absent(),
    Value<double?> basisQuantity = const Value.absent(),
    Value<String?> basisUnit = const Value.absent(),
    Value<double?> basisKcal = const Value.absent(),
    Value<double?> basisProtein = const Value.absent(),
    Value<double?> basisCarb = const Value.absent(),
    Value<double?> basisFat = const Value.absent(),
    Value<double?> basisPhysicalGrams = const Value.absent(),
    bool? basisNeedsReview,
    Value<String?> sourceUrl = const Value.absent(),
    Value<String?> sourceTitle = const Value.absent(),
    Value<DateTime?> sourceRetrievedAt = const Value.absent(),
    Value<String?> sourceInferredFields = const Value.absent(),
  }) => FoodCacheData(
    id: id ?? this.id,
    name: name ?? this.name,
    source: source ?? this.source,
    kcal100: kcal100 ?? this.kcal100,
    protein100: protein100 ?? this.protein100,
    carb100: carb100 ?? this.carb100,
    fat100: fat100 ?? this.fat100,
    isEstimate: isEstimate ?? this.isEstimate,
    userOverride: userOverride ?? this.userOverride,
    gramsPerPiece: gramsPerPiece.present
        ? gramsPerPiece.value
        : this.gramsPerPiece,
    fibre100: fibre100.present ? fibre100.value : this.fibre100,
    sodium100: sodium100.present ? sodium100.value : this.sodium100,
    basisQuantity: basisQuantity.present
        ? basisQuantity.value
        : this.basisQuantity,
    basisUnit: basisUnit.present ? basisUnit.value : this.basisUnit,
    basisKcal: basisKcal.present ? basisKcal.value : this.basisKcal,
    basisProtein: basisProtein.present ? basisProtein.value : this.basisProtein,
    basisCarb: basisCarb.present ? basisCarb.value : this.basisCarb,
    basisFat: basisFat.present ? basisFat.value : this.basisFat,
    basisPhysicalGrams: basisPhysicalGrams.present
        ? basisPhysicalGrams.value
        : this.basisPhysicalGrams,
    basisNeedsReview: basisNeedsReview ?? this.basisNeedsReview,
    sourceUrl: sourceUrl.present ? sourceUrl.value : this.sourceUrl,
    sourceTitle: sourceTitle.present ? sourceTitle.value : this.sourceTitle,
    sourceRetrievedAt: sourceRetrievedAt.present
        ? sourceRetrievedAt.value
        : this.sourceRetrievedAt,
    sourceInferredFields: sourceInferredFields.present
        ? sourceInferredFields.value
        : this.sourceInferredFields,
  );
  FoodCacheData copyWithCompanion(FoodCacheCompanion data) {
    return FoodCacheData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      source: data.source.present ? data.source.value : this.source,
      kcal100: data.kcal100.present ? data.kcal100.value : this.kcal100,
      protein100: data.protein100.present
          ? data.protein100.value
          : this.protein100,
      carb100: data.carb100.present ? data.carb100.value : this.carb100,
      fat100: data.fat100.present ? data.fat100.value : this.fat100,
      isEstimate: data.isEstimate.present
          ? data.isEstimate.value
          : this.isEstimate,
      userOverride: data.userOverride.present
          ? data.userOverride.value
          : this.userOverride,
      gramsPerPiece: data.gramsPerPiece.present
          ? data.gramsPerPiece.value
          : this.gramsPerPiece,
      fibre100: data.fibre100.present ? data.fibre100.value : this.fibre100,
      sodium100: data.sodium100.present ? data.sodium100.value : this.sodium100,
      basisQuantity: data.basisQuantity.present
          ? data.basisQuantity.value
          : this.basisQuantity,
      basisUnit: data.basisUnit.present ? data.basisUnit.value : this.basisUnit,
      basisKcal: data.basisKcal.present ? data.basisKcal.value : this.basisKcal,
      basisProtein: data.basisProtein.present
          ? data.basisProtein.value
          : this.basisProtein,
      basisCarb: data.basisCarb.present ? data.basisCarb.value : this.basisCarb,
      basisFat: data.basisFat.present ? data.basisFat.value : this.basisFat,
      basisPhysicalGrams: data.basisPhysicalGrams.present
          ? data.basisPhysicalGrams.value
          : this.basisPhysicalGrams,
      basisNeedsReview: data.basisNeedsReview.present
          ? data.basisNeedsReview.value
          : this.basisNeedsReview,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      sourceTitle: data.sourceTitle.present
          ? data.sourceTitle.value
          : this.sourceTitle,
      sourceRetrievedAt: data.sourceRetrievedAt.present
          ? data.sourceRetrievedAt.value
          : this.sourceRetrievedAt,
      sourceInferredFields: data.sourceInferredFields.present
          ? data.sourceInferredFields.value
          : this.sourceInferredFields,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodCacheData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('source: $source, ')
          ..write('kcal100: $kcal100, ')
          ..write('protein100: $protein100, ')
          ..write('carb100: $carb100, ')
          ..write('fat100: $fat100, ')
          ..write('isEstimate: $isEstimate, ')
          ..write('userOverride: $userOverride, ')
          ..write('gramsPerPiece: $gramsPerPiece, ')
          ..write('fibre100: $fibre100, ')
          ..write('sodium100: $sodium100, ')
          ..write('basisQuantity: $basisQuantity, ')
          ..write('basisUnit: $basisUnit, ')
          ..write('basisKcal: $basisKcal, ')
          ..write('basisProtein: $basisProtein, ')
          ..write('basisCarb: $basisCarb, ')
          ..write('basisFat: $basisFat, ')
          ..write('basisPhysicalGrams: $basisPhysicalGrams, ')
          ..write('basisNeedsReview: $basisNeedsReview, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('sourceTitle: $sourceTitle, ')
          ..write('sourceRetrievedAt: $sourceRetrievedAt, ')
          ..write('sourceInferredFields: $sourceInferredFields')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    source,
    kcal100,
    protein100,
    carb100,
    fat100,
    isEstimate,
    userOverride,
    gramsPerPiece,
    fibre100,
    sodium100,
    basisQuantity,
    basisUnit,
    basisKcal,
    basisProtein,
    basisCarb,
    basisFat,
    basisPhysicalGrams,
    basisNeedsReview,
    sourceUrl,
    sourceTitle,
    sourceRetrievedAt,
    sourceInferredFields,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodCacheData &&
          other.id == this.id &&
          other.name == this.name &&
          other.source == this.source &&
          other.kcal100 == this.kcal100 &&
          other.protein100 == this.protein100 &&
          other.carb100 == this.carb100 &&
          other.fat100 == this.fat100 &&
          other.isEstimate == this.isEstimate &&
          other.userOverride == this.userOverride &&
          other.gramsPerPiece == this.gramsPerPiece &&
          other.fibre100 == this.fibre100 &&
          other.sodium100 == this.sodium100 &&
          other.basisQuantity == this.basisQuantity &&
          other.basisUnit == this.basisUnit &&
          other.basisKcal == this.basisKcal &&
          other.basisProtein == this.basisProtein &&
          other.basisCarb == this.basisCarb &&
          other.basisFat == this.basisFat &&
          other.basisPhysicalGrams == this.basisPhysicalGrams &&
          other.basisNeedsReview == this.basisNeedsReview &&
          other.sourceUrl == this.sourceUrl &&
          other.sourceTitle == this.sourceTitle &&
          other.sourceRetrievedAt == this.sourceRetrievedAt &&
          other.sourceInferredFields == this.sourceInferredFields);
}

class FoodCacheCompanion extends UpdateCompanion<FoodCacheData> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> source;
  final Value<double> kcal100;
  final Value<double> protein100;
  final Value<double> carb100;
  final Value<double> fat100;
  final Value<bool> isEstimate;
  final Value<bool> userOverride;
  final Value<double?> gramsPerPiece;
  final Value<double?> fibre100;
  final Value<double?> sodium100;
  final Value<double?> basisQuantity;
  final Value<String?> basisUnit;
  final Value<double?> basisKcal;
  final Value<double?> basisProtein;
  final Value<double?> basisCarb;
  final Value<double?> basisFat;
  final Value<double?> basisPhysicalGrams;
  final Value<bool> basisNeedsReview;
  final Value<String?> sourceUrl;
  final Value<String?> sourceTitle;
  final Value<DateTime?> sourceRetrievedAt;
  final Value<String?> sourceInferredFields;
  const FoodCacheCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.source = const Value.absent(),
    this.kcal100 = const Value.absent(),
    this.protein100 = const Value.absent(),
    this.carb100 = const Value.absent(),
    this.fat100 = const Value.absent(),
    this.isEstimate = const Value.absent(),
    this.userOverride = const Value.absent(),
    this.gramsPerPiece = const Value.absent(),
    this.fibre100 = const Value.absent(),
    this.sodium100 = const Value.absent(),
    this.basisQuantity = const Value.absent(),
    this.basisUnit = const Value.absent(),
    this.basisKcal = const Value.absent(),
    this.basisProtein = const Value.absent(),
    this.basisCarb = const Value.absent(),
    this.basisFat = const Value.absent(),
    this.basisPhysicalGrams = const Value.absent(),
    this.basisNeedsReview = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.sourceTitle = const Value.absent(),
    this.sourceRetrievedAt = const Value.absent(),
    this.sourceInferredFields = const Value.absent(),
  });
  FoodCacheCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String source,
    required double kcal100,
    required double protein100,
    required double carb100,
    required double fat100,
    this.isEstimate = const Value.absent(),
    this.userOverride = const Value.absent(),
    this.gramsPerPiece = const Value.absent(),
    this.fibre100 = const Value.absent(),
    this.sodium100 = const Value.absent(),
    this.basisQuantity = const Value.absent(),
    this.basisUnit = const Value.absent(),
    this.basisKcal = const Value.absent(),
    this.basisProtein = const Value.absent(),
    this.basisCarb = const Value.absent(),
    this.basisFat = const Value.absent(),
    this.basisPhysicalGrams = const Value.absent(),
    this.basisNeedsReview = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.sourceTitle = const Value.absent(),
    this.sourceRetrievedAt = const Value.absent(),
    this.sourceInferredFields = const Value.absent(),
  }) : name = Value(name),
       source = Value(source),
       kcal100 = Value(kcal100),
       protein100 = Value(protein100),
       carb100 = Value(carb100),
       fat100 = Value(fat100);
  static Insertable<FoodCacheData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? source,
    Expression<double>? kcal100,
    Expression<double>? protein100,
    Expression<double>? carb100,
    Expression<double>? fat100,
    Expression<bool>? isEstimate,
    Expression<bool>? userOverride,
    Expression<double>? gramsPerPiece,
    Expression<double>? fibre100,
    Expression<double>? sodium100,
    Expression<double>? basisQuantity,
    Expression<String>? basisUnit,
    Expression<double>? basisKcal,
    Expression<double>? basisProtein,
    Expression<double>? basisCarb,
    Expression<double>? basisFat,
    Expression<double>? basisPhysicalGrams,
    Expression<bool>? basisNeedsReview,
    Expression<String>? sourceUrl,
    Expression<String>? sourceTitle,
    Expression<DateTime>? sourceRetrievedAt,
    Expression<String>? sourceInferredFields,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (source != null) 'source': source,
      if (kcal100 != null) 'kcal100': kcal100,
      if (protein100 != null) 'protein100': protein100,
      if (carb100 != null) 'carb100': carb100,
      if (fat100 != null) 'fat100': fat100,
      if (isEstimate != null) 'is_estimate': isEstimate,
      if (userOverride != null) 'user_override': userOverride,
      if (gramsPerPiece != null) 'grams_per_piece': gramsPerPiece,
      if (fibre100 != null) 'fibre100': fibre100,
      if (sodium100 != null) 'sodium100': sodium100,
      if (basisQuantity != null) 'basis_quantity': basisQuantity,
      if (basisUnit != null) 'basis_unit': basisUnit,
      if (basisKcal != null) 'basis_kcal': basisKcal,
      if (basisProtein != null) 'basis_protein': basisProtein,
      if (basisCarb != null) 'basis_carb': basisCarb,
      if (basisFat != null) 'basis_fat': basisFat,
      if (basisPhysicalGrams != null)
        'basis_physical_grams': basisPhysicalGrams,
      if (basisNeedsReview != null) 'basis_needs_review': basisNeedsReview,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (sourceTitle != null) 'source_title': sourceTitle,
      if (sourceRetrievedAt != null) 'source_retrieved_at': sourceRetrievedAt,
      if (sourceInferredFields != null)
        'source_inferred_fields': sourceInferredFields,
    });
  }

  FoodCacheCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? source,
    Value<double>? kcal100,
    Value<double>? protein100,
    Value<double>? carb100,
    Value<double>? fat100,
    Value<bool>? isEstimate,
    Value<bool>? userOverride,
    Value<double?>? gramsPerPiece,
    Value<double?>? fibre100,
    Value<double?>? sodium100,
    Value<double?>? basisQuantity,
    Value<String?>? basisUnit,
    Value<double?>? basisKcal,
    Value<double?>? basisProtein,
    Value<double?>? basisCarb,
    Value<double?>? basisFat,
    Value<double?>? basisPhysicalGrams,
    Value<bool>? basisNeedsReview,
    Value<String?>? sourceUrl,
    Value<String?>? sourceTitle,
    Value<DateTime?>? sourceRetrievedAt,
    Value<String?>? sourceInferredFields,
  }) {
    return FoodCacheCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      source: source ?? this.source,
      kcal100: kcal100 ?? this.kcal100,
      protein100: protein100 ?? this.protein100,
      carb100: carb100 ?? this.carb100,
      fat100: fat100 ?? this.fat100,
      isEstimate: isEstimate ?? this.isEstimate,
      userOverride: userOverride ?? this.userOverride,
      gramsPerPiece: gramsPerPiece ?? this.gramsPerPiece,
      fibre100: fibre100 ?? this.fibre100,
      sodium100: sodium100 ?? this.sodium100,
      basisQuantity: basisQuantity ?? this.basisQuantity,
      basisUnit: basisUnit ?? this.basisUnit,
      basisKcal: basisKcal ?? this.basisKcal,
      basisProtein: basisProtein ?? this.basisProtein,
      basisCarb: basisCarb ?? this.basisCarb,
      basisFat: basisFat ?? this.basisFat,
      basisPhysicalGrams: basisPhysicalGrams ?? this.basisPhysicalGrams,
      basisNeedsReview: basisNeedsReview ?? this.basisNeedsReview,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      sourceRetrievedAt: sourceRetrievedAt ?? this.sourceRetrievedAt,
      sourceInferredFields: sourceInferredFields ?? this.sourceInferredFields,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (kcal100.present) {
      map['kcal100'] = Variable<double>(kcal100.value);
    }
    if (protein100.present) {
      map['protein100'] = Variable<double>(protein100.value);
    }
    if (carb100.present) {
      map['carb100'] = Variable<double>(carb100.value);
    }
    if (fat100.present) {
      map['fat100'] = Variable<double>(fat100.value);
    }
    if (isEstimate.present) {
      map['is_estimate'] = Variable<bool>(isEstimate.value);
    }
    if (userOverride.present) {
      map['user_override'] = Variable<bool>(userOverride.value);
    }
    if (gramsPerPiece.present) {
      map['grams_per_piece'] = Variable<double>(gramsPerPiece.value);
    }
    if (fibre100.present) {
      map['fibre100'] = Variable<double>(fibre100.value);
    }
    if (sodium100.present) {
      map['sodium100'] = Variable<double>(sodium100.value);
    }
    if (basisQuantity.present) {
      map['basis_quantity'] = Variable<double>(basisQuantity.value);
    }
    if (basisUnit.present) {
      map['basis_unit'] = Variable<String>(basisUnit.value);
    }
    if (basisKcal.present) {
      map['basis_kcal'] = Variable<double>(basisKcal.value);
    }
    if (basisProtein.present) {
      map['basis_protein'] = Variable<double>(basisProtein.value);
    }
    if (basisCarb.present) {
      map['basis_carb'] = Variable<double>(basisCarb.value);
    }
    if (basisFat.present) {
      map['basis_fat'] = Variable<double>(basisFat.value);
    }
    if (basisPhysicalGrams.present) {
      map['basis_physical_grams'] = Variable<double>(basisPhysicalGrams.value);
    }
    if (basisNeedsReview.present) {
      map['basis_needs_review'] = Variable<bool>(basisNeedsReview.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (sourceTitle.present) {
      map['source_title'] = Variable<String>(sourceTitle.value);
    }
    if (sourceRetrievedAt.present) {
      map['source_retrieved_at'] = Variable<DateTime>(sourceRetrievedAt.value);
    }
    if (sourceInferredFields.present) {
      map['source_inferred_fields'] = Variable<String>(
        sourceInferredFields.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodCacheCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('source: $source, ')
          ..write('kcal100: $kcal100, ')
          ..write('protein100: $protein100, ')
          ..write('carb100: $carb100, ')
          ..write('fat100: $fat100, ')
          ..write('isEstimate: $isEstimate, ')
          ..write('userOverride: $userOverride, ')
          ..write('gramsPerPiece: $gramsPerPiece, ')
          ..write('fibre100: $fibre100, ')
          ..write('sodium100: $sodium100, ')
          ..write('basisQuantity: $basisQuantity, ')
          ..write('basisUnit: $basisUnit, ')
          ..write('basisKcal: $basisKcal, ')
          ..write('basisProtein: $basisProtein, ')
          ..write('basisCarb: $basisCarb, ')
          ..write('basisFat: $basisFat, ')
          ..write('basisPhysicalGrams: $basisPhysicalGrams, ')
          ..write('basisNeedsReview: $basisNeedsReview, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('sourceTitle: $sourceTitle, ')
          ..write('sourceRetrievedAt: $sourceRetrievedAt, ')
          ..write('sourceInferredFields: $sourceInferredFields')
          ..write(')'))
        .toString();
  }
}

class $FoodUnitWeightsTable extends FoodUnitWeights
    with TableInfo<$FoodUnitWeightsTable, FoodUnitWeightRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodUnitWeightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _foodKeyMeta = const VerificationMeta(
    'foodKey',
  );
  @override
  late final GeneratedColumn<String> foodKey = GeneratedColumn<String>(
    'food_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foodNameMeta = const VerificationMeta(
    'foodName',
  );
  @override
  late final GeneratedColumn<String> foodName = GeneratedColumn<String>(
    'food_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gramsPerUnitMeta = const VerificationMeta(
    'gramsPerUnit',
  );
  @override
  late final GeneratedColumn<double> gramsPerUnit = GeneratedColumn<double>(
    'grams_per_unit',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTitleMeta = const VerificationMeta(
    'sourceTitle',
  );
  @override
  late final GeneratedColumn<String> sourceTitle = GeneratedColumn<String>(
    'source_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceRetrievedAtMeta = const VerificationMeta(
    'sourceRetrievedAt',
  );
  @override
  late final GeneratedColumn<DateTime> sourceRetrievedAt =
      GeneratedColumn<DateTime>(
        'source_retrieved_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    foodKey,
    foodName,
    unit,
    gramsPerUnit,
    kind,
    sourceUrl,
    sourceTitle,
    sourceRetrievedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_unit_weights';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodUnitWeightRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('food_key')) {
      context.handle(
        _foodKeyMeta,
        foodKey.isAcceptableOrUnknown(data['food_key']!, _foodKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_foodKeyMeta);
    }
    if (data.containsKey('food_name')) {
      context.handle(
        _foodNameMeta,
        foodName.isAcceptableOrUnknown(data['food_name']!, _foodNameMeta),
      );
    } else if (isInserting) {
      context.missing(_foodNameMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('grams_per_unit')) {
      context.handle(
        _gramsPerUnitMeta,
        gramsPerUnit.isAcceptableOrUnknown(
          data['grams_per_unit']!,
          _gramsPerUnitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_gramsPerUnitMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceUrlMeta);
    }
    if (data.containsKey('source_title')) {
      context.handle(
        _sourceTitleMeta,
        sourceTitle.isAcceptableOrUnknown(
          data['source_title']!,
          _sourceTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceTitleMeta);
    }
    if (data.containsKey('source_retrieved_at')) {
      context.handle(
        _sourceRetrievedAtMeta,
        sourceRetrievedAt.isAcceptableOrUnknown(
          data['source_retrieved_at']!,
          _sourceRetrievedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceRetrievedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {foodKey, unit};
  @override
  FoodUnitWeightRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodUnitWeightRow(
      foodKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_key'],
      )!,
      foodName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_name'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      gramsPerUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams_per_unit'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      )!,
      sourceTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_title'],
      )!,
      sourceRetrievedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}source_retrieved_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FoodUnitWeightsTable createAlias(String alias) {
    return $FoodUnitWeightsTable(attachedDatabase, alias);
  }
}

class FoodUnitWeightRow extends DataClass
    implements Insertable<FoodUnitWeightRow> {
  final String foodKey;
  final String foodName;
  final String unit;
  final double gramsPerUnit;
  final String kind;
  final String sourceUrl;
  final String sourceTitle;
  final DateTime sourceRetrievedAt;
  final DateTime updatedAt;
  const FoodUnitWeightRow({
    required this.foodKey,
    required this.foodName,
    required this.unit,
    required this.gramsPerUnit,
    required this.kind,
    required this.sourceUrl,
    required this.sourceTitle,
    required this.sourceRetrievedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['food_key'] = Variable<String>(foodKey);
    map['food_name'] = Variable<String>(foodName);
    map['unit'] = Variable<String>(unit);
    map['grams_per_unit'] = Variable<double>(gramsPerUnit);
    map['kind'] = Variable<String>(kind);
    map['source_url'] = Variable<String>(sourceUrl);
    map['source_title'] = Variable<String>(sourceTitle);
    map['source_retrieved_at'] = Variable<DateTime>(sourceRetrievedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FoodUnitWeightsCompanion toCompanion(bool nullToAbsent) {
    return FoodUnitWeightsCompanion(
      foodKey: Value(foodKey),
      foodName: Value(foodName),
      unit: Value(unit),
      gramsPerUnit: Value(gramsPerUnit),
      kind: Value(kind),
      sourceUrl: Value(sourceUrl),
      sourceTitle: Value(sourceTitle),
      sourceRetrievedAt: Value(sourceRetrievedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FoodUnitWeightRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodUnitWeightRow(
      foodKey: serializer.fromJson<String>(json['foodKey']),
      foodName: serializer.fromJson<String>(json['foodName']),
      unit: serializer.fromJson<String>(json['unit']),
      gramsPerUnit: serializer.fromJson<double>(json['gramsPerUnit']),
      kind: serializer.fromJson<String>(json['kind']),
      sourceUrl: serializer.fromJson<String>(json['sourceUrl']),
      sourceTitle: serializer.fromJson<String>(json['sourceTitle']),
      sourceRetrievedAt: serializer.fromJson<DateTime>(
        json['sourceRetrievedAt'],
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'foodKey': serializer.toJson<String>(foodKey),
      'foodName': serializer.toJson<String>(foodName),
      'unit': serializer.toJson<String>(unit),
      'gramsPerUnit': serializer.toJson<double>(gramsPerUnit),
      'kind': serializer.toJson<String>(kind),
      'sourceUrl': serializer.toJson<String>(sourceUrl),
      'sourceTitle': serializer.toJson<String>(sourceTitle),
      'sourceRetrievedAt': serializer.toJson<DateTime>(sourceRetrievedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FoodUnitWeightRow copyWith({
    String? foodKey,
    String? foodName,
    String? unit,
    double? gramsPerUnit,
    String? kind,
    String? sourceUrl,
    String? sourceTitle,
    DateTime? sourceRetrievedAt,
    DateTime? updatedAt,
  }) => FoodUnitWeightRow(
    foodKey: foodKey ?? this.foodKey,
    foodName: foodName ?? this.foodName,
    unit: unit ?? this.unit,
    gramsPerUnit: gramsPerUnit ?? this.gramsPerUnit,
    kind: kind ?? this.kind,
    sourceUrl: sourceUrl ?? this.sourceUrl,
    sourceTitle: sourceTitle ?? this.sourceTitle,
    sourceRetrievedAt: sourceRetrievedAt ?? this.sourceRetrievedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FoodUnitWeightRow copyWithCompanion(FoodUnitWeightsCompanion data) {
    return FoodUnitWeightRow(
      foodKey: data.foodKey.present ? data.foodKey.value : this.foodKey,
      foodName: data.foodName.present ? data.foodName.value : this.foodName,
      unit: data.unit.present ? data.unit.value : this.unit,
      gramsPerUnit: data.gramsPerUnit.present
          ? data.gramsPerUnit.value
          : this.gramsPerUnit,
      kind: data.kind.present ? data.kind.value : this.kind,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      sourceTitle: data.sourceTitle.present
          ? data.sourceTitle.value
          : this.sourceTitle,
      sourceRetrievedAt: data.sourceRetrievedAt.present
          ? data.sourceRetrievedAt.value
          : this.sourceRetrievedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodUnitWeightRow(')
          ..write('foodKey: $foodKey, ')
          ..write('foodName: $foodName, ')
          ..write('unit: $unit, ')
          ..write('gramsPerUnit: $gramsPerUnit, ')
          ..write('kind: $kind, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('sourceTitle: $sourceTitle, ')
          ..write('sourceRetrievedAt: $sourceRetrievedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    foodKey,
    foodName,
    unit,
    gramsPerUnit,
    kind,
    sourceUrl,
    sourceTitle,
    sourceRetrievedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodUnitWeightRow &&
          other.foodKey == this.foodKey &&
          other.foodName == this.foodName &&
          other.unit == this.unit &&
          other.gramsPerUnit == this.gramsPerUnit &&
          other.kind == this.kind &&
          other.sourceUrl == this.sourceUrl &&
          other.sourceTitle == this.sourceTitle &&
          other.sourceRetrievedAt == this.sourceRetrievedAt &&
          other.updatedAt == this.updatedAt);
}

class FoodUnitWeightsCompanion extends UpdateCompanion<FoodUnitWeightRow> {
  final Value<String> foodKey;
  final Value<String> foodName;
  final Value<String> unit;
  final Value<double> gramsPerUnit;
  final Value<String> kind;
  final Value<String> sourceUrl;
  final Value<String> sourceTitle;
  final Value<DateTime> sourceRetrievedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FoodUnitWeightsCompanion({
    this.foodKey = const Value.absent(),
    this.foodName = const Value.absent(),
    this.unit = const Value.absent(),
    this.gramsPerUnit = const Value.absent(),
    this.kind = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.sourceTitle = const Value.absent(),
    this.sourceRetrievedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoodUnitWeightsCompanion.insert({
    required String foodKey,
    required String foodName,
    required String unit,
    required double gramsPerUnit,
    required String kind,
    required String sourceUrl,
    required String sourceTitle,
    required DateTime sourceRetrievedAt,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : foodKey = Value(foodKey),
       foodName = Value(foodName),
       unit = Value(unit),
       gramsPerUnit = Value(gramsPerUnit),
       kind = Value(kind),
       sourceUrl = Value(sourceUrl),
       sourceTitle = Value(sourceTitle),
       sourceRetrievedAt = Value(sourceRetrievedAt);
  static Insertable<FoodUnitWeightRow> custom({
    Expression<String>? foodKey,
    Expression<String>? foodName,
    Expression<String>? unit,
    Expression<double>? gramsPerUnit,
    Expression<String>? kind,
    Expression<String>? sourceUrl,
    Expression<String>? sourceTitle,
    Expression<DateTime>? sourceRetrievedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (foodKey != null) 'food_key': foodKey,
      if (foodName != null) 'food_name': foodName,
      if (unit != null) 'unit': unit,
      if (gramsPerUnit != null) 'grams_per_unit': gramsPerUnit,
      if (kind != null) 'kind': kind,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (sourceTitle != null) 'source_title': sourceTitle,
      if (sourceRetrievedAt != null) 'source_retrieved_at': sourceRetrievedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoodUnitWeightsCompanion copyWith({
    Value<String>? foodKey,
    Value<String>? foodName,
    Value<String>? unit,
    Value<double>? gramsPerUnit,
    Value<String>? kind,
    Value<String>? sourceUrl,
    Value<String>? sourceTitle,
    Value<DateTime>? sourceRetrievedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FoodUnitWeightsCompanion(
      foodKey: foodKey ?? this.foodKey,
      foodName: foodName ?? this.foodName,
      unit: unit ?? this.unit,
      gramsPerUnit: gramsPerUnit ?? this.gramsPerUnit,
      kind: kind ?? this.kind,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      sourceRetrievedAt: sourceRetrievedAt ?? this.sourceRetrievedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (foodKey.present) {
      map['food_key'] = Variable<String>(foodKey.value);
    }
    if (foodName.present) {
      map['food_name'] = Variable<String>(foodName.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (gramsPerUnit.present) {
      map['grams_per_unit'] = Variable<double>(gramsPerUnit.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (sourceTitle.present) {
      map['source_title'] = Variable<String>(sourceTitle.value);
    }
    if (sourceRetrievedAt.present) {
      map['source_retrieved_at'] = Variable<DateTime>(sourceRetrievedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodUnitWeightsCompanion(')
          ..write('foodKey: $foodKey, ')
          ..write('foodName: $foodName, ')
          ..write('unit: $unit, ')
          ..write('gramsPerUnit: $gramsPerUnit, ')
          ..write('kind: $kind, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('sourceTitle: $sourceTitle, ')
          ..write('sourceRetrievedAt: $sourceRetrievedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LogEntriesTable extends LogEntries
    with TableInfo<$LogEntriesTable, LogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LogEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foodNameMeta = const VerificationMeta(
    'foodName',
  );
  @override
  late final GeneratedColumn<String> foodName = GeneratedColumn<String>(
    'food_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
    'grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<double> kcal = GeneratedColumn<double>(
    'kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinMeta = const VerificationMeta(
    'protein',
  );
  @override
  late final GeneratedColumn<double> protein = GeneratedColumn<double>(
    'protein',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbMeta = const VerificationMeta('carb');
  @override
  late final GeneratedColumn<double> carb = GeneratedColumn<double>(
    'carb',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatMeta = const VerificationMeta('fat');
  @override
  late final GeneratedColumn<double> fat = GeneratedColumn<double>(
    'fat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fibreMeta = const VerificationMeta('fibre');
  @override
  late final GeneratedColumn<double> fibre = GeneratedColumn<double>(
    'fibre',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<int> recipeId = GeneratedColumn<int>(
    'recipe_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _portionQuantityMeta = const VerificationMeta(
    'portionQuantity',
  );
  @override
  late final GeneratedColumn<double> portionQuantity = GeneratedColumn<double>(
    'portion_quantity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _portionUnitMeta = const VerificationMeta(
    'portionUnit',
  );
  @override
  late final GeneratedColumn<String> portionUnit = GeneratedColumn<String>(
    'portion_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _portionWeightGramsPerUnitMeta =
      const VerificationMeta('portionWeightGramsPerUnit');
  @override
  late final GeneratedColumn<double> portionWeightGramsPerUnit =
      GeneratedColumn<double>(
        'portion_weight_grams_per_unit',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _portionWeightUnitMeta = const VerificationMeta(
    'portionWeightUnit',
  );
  @override
  late final GeneratedColumn<String> portionWeightUnit =
      GeneratedColumn<String>(
        'portion_weight_unit',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _portionWeightIsEstimateMeta =
      const VerificationMeta('portionWeightIsEstimate');
  @override
  late final GeneratedColumn<bool> portionWeightIsEstimate =
      GeneratedColumn<bool>(
        'portion_weight_is_estimate',
        aliasedName,
        true,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("portion_weight_is_estimate" IN (0, 1))',
        ),
      );
  static const VerificationMeta _portionWeightSourceUrlMeta =
      const VerificationMeta('portionWeightSourceUrl');
  @override
  late final GeneratedColumn<String> portionWeightSourceUrl =
      GeneratedColumn<String>(
        'portion_weight_source_url',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _portionWeightSourceTitleMeta =
      const VerificationMeta('portionWeightSourceTitle');
  @override
  late final GeneratedColumn<String> portionWeightSourceTitle =
      GeneratedColumn<String>(
        'portion_weight_source_title',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _portionWeightSourceRetrievedAtMeta =
      const VerificationMeta('portionWeightSourceRetrievedAt');
  @override
  late final GeneratedColumn<DateTime> portionWeightSourceRetrievedAt =
      GeneratedColumn<DateTime>(
        'portion_weight_source_retrieved_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    foodName,
    grams,
    kcal,
    protein,
    carb,
    fat,
    fibre,
    source,
    recipeId,
    portionQuantity,
    portionUnit,
    portionWeightGramsPerUnit,
    portionWeightUnit,
    portionWeightIsEstimate,
    portionWeightSourceUrl,
    portionWeightSourceTitle,
    portionWeightSourceRetrievedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'log_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LogEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('food_name')) {
      context.handle(
        _foodNameMeta,
        foodName.isAcceptableOrUnknown(data['food_name']!, _foodNameMeta),
      );
    } else if (isInserting) {
      context.missing(_foodNameMeta);
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    if (data.containsKey('kcal')) {
      context.handle(
        _kcalMeta,
        kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta),
      );
    } else if (isInserting) {
      context.missing(_kcalMeta);
    }
    if (data.containsKey('protein')) {
      context.handle(
        _proteinMeta,
        protein.isAcceptableOrUnknown(data['protein']!, _proteinMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinMeta);
    }
    if (data.containsKey('carb')) {
      context.handle(
        _carbMeta,
        carb.isAcceptableOrUnknown(data['carb']!, _carbMeta),
      );
    } else if (isInserting) {
      context.missing(_carbMeta);
    }
    if (data.containsKey('fat')) {
      context.handle(
        _fatMeta,
        fat.isAcceptableOrUnknown(data['fat']!, _fatMeta),
      );
    } else if (isInserting) {
      context.missing(_fatMeta);
    }
    if (data.containsKey('fibre')) {
      context.handle(
        _fibreMeta,
        fibre.isAcceptableOrUnknown(data['fibre']!, _fibreMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    }
    if (data.containsKey('portion_quantity')) {
      context.handle(
        _portionQuantityMeta,
        portionQuantity.isAcceptableOrUnknown(
          data['portion_quantity']!,
          _portionQuantityMeta,
        ),
      );
    }
    if (data.containsKey('portion_unit')) {
      context.handle(
        _portionUnitMeta,
        portionUnit.isAcceptableOrUnknown(
          data['portion_unit']!,
          _portionUnitMeta,
        ),
      );
    }
    if (data.containsKey('portion_weight_grams_per_unit')) {
      context.handle(
        _portionWeightGramsPerUnitMeta,
        portionWeightGramsPerUnit.isAcceptableOrUnknown(
          data['portion_weight_grams_per_unit']!,
          _portionWeightGramsPerUnitMeta,
        ),
      );
    }
    if (data.containsKey('portion_weight_unit')) {
      context.handle(
        _portionWeightUnitMeta,
        portionWeightUnit.isAcceptableOrUnknown(
          data['portion_weight_unit']!,
          _portionWeightUnitMeta,
        ),
      );
    }
    if (data.containsKey('portion_weight_is_estimate')) {
      context.handle(
        _portionWeightIsEstimateMeta,
        portionWeightIsEstimate.isAcceptableOrUnknown(
          data['portion_weight_is_estimate']!,
          _portionWeightIsEstimateMeta,
        ),
      );
    }
    if (data.containsKey('portion_weight_source_url')) {
      context.handle(
        _portionWeightSourceUrlMeta,
        portionWeightSourceUrl.isAcceptableOrUnknown(
          data['portion_weight_source_url']!,
          _portionWeightSourceUrlMeta,
        ),
      );
    }
    if (data.containsKey('portion_weight_source_title')) {
      context.handle(
        _portionWeightSourceTitleMeta,
        portionWeightSourceTitle.isAcceptableOrUnknown(
          data['portion_weight_source_title']!,
          _portionWeightSourceTitleMeta,
        ),
      );
    }
    if (data.containsKey('portion_weight_source_retrieved_at')) {
      context.handle(
        _portionWeightSourceRetrievedAtMeta,
        portionWeightSourceRetrievedAt.isAcceptableOrUnknown(
          data['portion_weight_source_retrieved_at']!,
          _portionWeightSourceRetrievedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LogEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      foodName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_name'],
      )!,
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      )!,
      kcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal'],
      )!,
      protein: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein'],
      )!,
      carb: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carb'],
      )!,
      fat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat'],
      )!,
      fibre: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fibre'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recipe_id'],
      ),
      portionQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}portion_quantity'],
      ),
      portionUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}portion_unit'],
      ),
      portionWeightGramsPerUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}portion_weight_grams_per_unit'],
      ),
      portionWeightUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}portion_weight_unit'],
      ),
      portionWeightIsEstimate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}portion_weight_is_estimate'],
      ),
      portionWeightSourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}portion_weight_source_url'],
      ),
      portionWeightSourceTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}portion_weight_source_title'],
      ),
      portionWeightSourceRetrievedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}portion_weight_source_retrieved_at'],
      ),
    );
  }

  @override
  $LogEntriesTable createAlias(String alias) {
    return $LogEntriesTable(attachedDatabase, alias);
  }
}

class LogEntry extends DataClass implements Insertable<LogEntry> {
  final int id;
  final String date;
  final String foodName;
  final double grams;
  final double kcal;
  final double protein;
  final double carb;
  final double fat;
  final double? fibre;
  final String source;
  final int? recipeId;
  final double? portionQuantity;
  final String? portionUnit;
  final double? portionWeightGramsPerUnit;
  final String? portionWeightUnit;
  final bool? portionWeightIsEstimate;
  final String? portionWeightSourceUrl;
  final String? portionWeightSourceTitle;
  final DateTime? portionWeightSourceRetrievedAt;
  const LogEntry({
    required this.id,
    required this.date,
    required this.foodName,
    required this.grams,
    required this.kcal,
    required this.protein,
    required this.carb,
    required this.fat,
    this.fibre,
    required this.source,
    this.recipeId,
    this.portionQuantity,
    this.portionUnit,
    this.portionWeightGramsPerUnit,
    this.portionWeightUnit,
    this.portionWeightIsEstimate,
    this.portionWeightSourceUrl,
    this.portionWeightSourceTitle,
    this.portionWeightSourceRetrievedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<String>(date);
    map['food_name'] = Variable<String>(foodName);
    map['grams'] = Variable<double>(grams);
    map['kcal'] = Variable<double>(kcal);
    map['protein'] = Variable<double>(protein);
    map['carb'] = Variable<double>(carb);
    map['fat'] = Variable<double>(fat);
    if (!nullToAbsent || fibre != null) {
      map['fibre'] = Variable<double>(fibre);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || recipeId != null) {
      map['recipe_id'] = Variable<int>(recipeId);
    }
    if (!nullToAbsent || portionQuantity != null) {
      map['portion_quantity'] = Variable<double>(portionQuantity);
    }
    if (!nullToAbsent || portionUnit != null) {
      map['portion_unit'] = Variable<String>(portionUnit);
    }
    if (!nullToAbsent || portionWeightGramsPerUnit != null) {
      map['portion_weight_grams_per_unit'] = Variable<double>(
        portionWeightGramsPerUnit,
      );
    }
    if (!nullToAbsent || portionWeightUnit != null) {
      map['portion_weight_unit'] = Variable<String>(portionWeightUnit);
    }
    if (!nullToAbsent || portionWeightIsEstimate != null) {
      map['portion_weight_is_estimate'] = Variable<bool>(
        portionWeightIsEstimate,
      );
    }
    if (!nullToAbsent || portionWeightSourceUrl != null) {
      map['portion_weight_source_url'] = Variable<String>(
        portionWeightSourceUrl,
      );
    }
    if (!nullToAbsent || portionWeightSourceTitle != null) {
      map['portion_weight_source_title'] = Variable<String>(
        portionWeightSourceTitle,
      );
    }
    if (!nullToAbsent || portionWeightSourceRetrievedAt != null) {
      map['portion_weight_source_retrieved_at'] = Variable<DateTime>(
        portionWeightSourceRetrievedAt,
      );
    }
    return map;
  }

  LogEntriesCompanion toCompanion(bool nullToAbsent) {
    return LogEntriesCompanion(
      id: Value(id),
      date: Value(date),
      foodName: Value(foodName),
      grams: Value(grams),
      kcal: Value(kcal),
      protein: Value(protein),
      carb: Value(carb),
      fat: Value(fat),
      fibre: fibre == null && nullToAbsent
          ? const Value.absent()
          : Value(fibre),
      source: Value(source),
      recipeId: recipeId == null && nullToAbsent
          ? const Value.absent()
          : Value(recipeId),
      portionQuantity: portionQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(portionQuantity),
      portionUnit: portionUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(portionUnit),
      portionWeightGramsPerUnit:
          portionWeightGramsPerUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(portionWeightGramsPerUnit),
      portionWeightUnit: portionWeightUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(portionWeightUnit),
      portionWeightIsEstimate: portionWeightIsEstimate == null && nullToAbsent
          ? const Value.absent()
          : Value(portionWeightIsEstimate),
      portionWeightSourceUrl: portionWeightSourceUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(portionWeightSourceUrl),
      portionWeightSourceTitle: portionWeightSourceTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(portionWeightSourceTitle),
      portionWeightSourceRetrievedAt:
          portionWeightSourceRetrievedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(portionWeightSourceRetrievedAt),
    );
  }

  factory LogEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LogEntry(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      foodName: serializer.fromJson<String>(json['foodName']),
      grams: serializer.fromJson<double>(json['grams']),
      kcal: serializer.fromJson<double>(json['kcal']),
      protein: serializer.fromJson<double>(json['protein']),
      carb: serializer.fromJson<double>(json['carb']),
      fat: serializer.fromJson<double>(json['fat']),
      fibre: serializer.fromJson<double?>(json['fibre']),
      source: serializer.fromJson<String>(json['source']),
      recipeId: serializer.fromJson<int?>(json['recipeId']),
      portionQuantity: serializer.fromJson<double?>(json['portionQuantity']),
      portionUnit: serializer.fromJson<String?>(json['portionUnit']),
      portionWeightGramsPerUnit: serializer.fromJson<double?>(
        json['portionWeightGramsPerUnit'],
      ),
      portionWeightUnit: serializer.fromJson<String?>(
        json['portionWeightUnit'],
      ),
      portionWeightIsEstimate: serializer.fromJson<bool?>(
        json['portionWeightIsEstimate'],
      ),
      portionWeightSourceUrl: serializer.fromJson<String?>(
        json['portionWeightSourceUrl'],
      ),
      portionWeightSourceTitle: serializer.fromJson<String?>(
        json['portionWeightSourceTitle'],
      ),
      portionWeightSourceRetrievedAt: serializer.fromJson<DateTime?>(
        json['portionWeightSourceRetrievedAt'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(date),
      'foodName': serializer.toJson<String>(foodName),
      'grams': serializer.toJson<double>(grams),
      'kcal': serializer.toJson<double>(kcal),
      'protein': serializer.toJson<double>(protein),
      'carb': serializer.toJson<double>(carb),
      'fat': serializer.toJson<double>(fat),
      'fibre': serializer.toJson<double?>(fibre),
      'source': serializer.toJson<String>(source),
      'recipeId': serializer.toJson<int?>(recipeId),
      'portionQuantity': serializer.toJson<double?>(portionQuantity),
      'portionUnit': serializer.toJson<String?>(portionUnit),
      'portionWeightGramsPerUnit': serializer.toJson<double?>(
        portionWeightGramsPerUnit,
      ),
      'portionWeightUnit': serializer.toJson<String?>(portionWeightUnit),
      'portionWeightIsEstimate': serializer.toJson<bool?>(
        portionWeightIsEstimate,
      ),
      'portionWeightSourceUrl': serializer.toJson<String?>(
        portionWeightSourceUrl,
      ),
      'portionWeightSourceTitle': serializer.toJson<String?>(
        portionWeightSourceTitle,
      ),
      'portionWeightSourceRetrievedAt': serializer.toJson<DateTime?>(
        portionWeightSourceRetrievedAt,
      ),
    };
  }

  LogEntry copyWith({
    int? id,
    String? date,
    String? foodName,
    double? grams,
    double? kcal,
    double? protein,
    double? carb,
    double? fat,
    Value<double?> fibre = const Value.absent(),
    String? source,
    Value<int?> recipeId = const Value.absent(),
    Value<double?> portionQuantity = const Value.absent(),
    Value<String?> portionUnit = const Value.absent(),
    Value<double?> portionWeightGramsPerUnit = const Value.absent(),
    Value<String?> portionWeightUnit = const Value.absent(),
    Value<bool?> portionWeightIsEstimate = const Value.absent(),
    Value<String?> portionWeightSourceUrl = const Value.absent(),
    Value<String?> portionWeightSourceTitle = const Value.absent(),
    Value<DateTime?> portionWeightSourceRetrievedAt = const Value.absent(),
  }) => LogEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    foodName: foodName ?? this.foodName,
    grams: grams ?? this.grams,
    kcal: kcal ?? this.kcal,
    protein: protein ?? this.protein,
    carb: carb ?? this.carb,
    fat: fat ?? this.fat,
    fibre: fibre.present ? fibre.value : this.fibre,
    source: source ?? this.source,
    recipeId: recipeId.present ? recipeId.value : this.recipeId,
    portionQuantity: portionQuantity.present
        ? portionQuantity.value
        : this.portionQuantity,
    portionUnit: portionUnit.present ? portionUnit.value : this.portionUnit,
    portionWeightGramsPerUnit: portionWeightGramsPerUnit.present
        ? portionWeightGramsPerUnit.value
        : this.portionWeightGramsPerUnit,
    portionWeightUnit: portionWeightUnit.present
        ? portionWeightUnit.value
        : this.portionWeightUnit,
    portionWeightIsEstimate: portionWeightIsEstimate.present
        ? portionWeightIsEstimate.value
        : this.portionWeightIsEstimate,
    portionWeightSourceUrl: portionWeightSourceUrl.present
        ? portionWeightSourceUrl.value
        : this.portionWeightSourceUrl,
    portionWeightSourceTitle: portionWeightSourceTitle.present
        ? portionWeightSourceTitle.value
        : this.portionWeightSourceTitle,
    portionWeightSourceRetrievedAt: portionWeightSourceRetrievedAt.present
        ? portionWeightSourceRetrievedAt.value
        : this.portionWeightSourceRetrievedAt,
  );
  LogEntry copyWithCompanion(LogEntriesCompanion data) {
    return LogEntry(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      foodName: data.foodName.present ? data.foodName.value : this.foodName,
      grams: data.grams.present ? data.grams.value : this.grams,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      protein: data.protein.present ? data.protein.value : this.protein,
      carb: data.carb.present ? data.carb.value : this.carb,
      fat: data.fat.present ? data.fat.value : this.fat,
      fibre: data.fibre.present ? data.fibre.value : this.fibre,
      source: data.source.present ? data.source.value : this.source,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      portionQuantity: data.portionQuantity.present
          ? data.portionQuantity.value
          : this.portionQuantity,
      portionUnit: data.portionUnit.present
          ? data.portionUnit.value
          : this.portionUnit,
      portionWeightGramsPerUnit: data.portionWeightGramsPerUnit.present
          ? data.portionWeightGramsPerUnit.value
          : this.portionWeightGramsPerUnit,
      portionWeightUnit: data.portionWeightUnit.present
          ? data.portionWeightUnit.value
          : this.portionWeightUnit,
      portionWeightIsEstimate: data.portionWeightIsEstimate.present
          ? data.portionWeightIsEstimate.value
          : this.portionWeightIsEstimate,
      portionWeightSourceUrl: data.portionWeightSourceUrl.present
          ? data.portionWeightSourceUrl.value
          : this.portionWeightSourceUrl,
      portionWeightSourceTitle: data.portionWeightSourceTitle.present
          ? data.portionWeightSourceTitle.value
          : this.portionWeightSourceTitle,
      portionWeightSourceRetrievedAt:
          data.portionWeightSourceRetrievedAt.present
          ? data.portionWeightSourceRetrievedAt.value
          : this.portionWeightSourceRetrievedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LogEntry(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('foodName: $foodName, ')
          ..write('grams: $grams, ')
          ..write('kcal: $kcal, ')
          ..write('protein: $protein, ')
          ..write('carb: $carb, ')
          ..write('fat: $fat, ')
          ..write('fibre: $fibre, ')
          ..write('source: $source, ')
          ..write('recipeId: $recipeId, ')
          ..write('portionQuantity: $portionQuantity, ')
          ..write('portionUnit: $portionUnit, ')
          ..write('portionWeightGramsPerUnit: $portionWeightGramsPerUnit, ')
          ..write('portionWeightUnit: $portionWeightUnit, ')
          ..write('portionWeightIsEstimate: $portionWeightIsEstimate, ')
          ..write('portionWeightSourceUrl: $portionWeightSourceUrl, ')
          ..write('portionWeightSourceTitle: $portionWeightSourceTitle, ')
          ..write(
            'portionWeightSourceRetrievedAt: $portionWeightSourceRetrievedAt',
          )
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    foodName,
    grams,
    kcal,
    protein,
    carb,
    fat,
    fibre,
    source,
    recipeId,
    portionQuantity,
    portionUnit,
    portionWeightGramsPerUnit,
    portionWeightUnit,
    portionWeightIsEstimate,
    portionWeightSourceUrl,
    portionWeightSourceTitle,
    portionWeightSourceRetrievedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LogEntry &&
          other.id == this.id &&
          other.date == this.date &&
          other.foodName == this.foodName &&
          other.grams == this.grams &&
          other.kcal == this.kcal &&
          other.protein == this.protein &&
          other.carb == this.carb &&
          other.fat == this.fat &&
          other.fibre == this.fibre &&
          other.source == this.source &&
          other.recipeId == this.recipeId &&
          other.portionQuantity == this.portionQuantity &&
          other.portionUnit == this.portionUnit &&
          other.portionWeightGramsPerUnit == this.portionWeightGramsPerUnit &&
          other.portionWeightUnit == this.portionWeightUnit &&
          other.portionWeightIsEstimate == this.portionWeightIsEstimate &&
          other.portionWeightSourceUrl == this.portionWeightSourceUrl &&
          other.portionWeightSourceTitle == this.portionWeightSourceTitle &&
          other.portionWeightSourceRetrievedAt ==
              this.portionWeightSourceRetrievedAt);
}

class LogEntriesCompanion extends UpdateCompanion<LogEntry> {
  final Value<int> id;
  final Value<String> date;
  final Value<String> foodName;
  final Value<double> grams;
  final Value<double> kcal;
  final Value<double> protein;
  final Value<double> carb;
  final Value<double> fat;
  final Value<double?> fibre;
  final Value<String> source;
  final Value<int?> recipeId;
  final Value<double?> portionQuantity;
  final Value<String?> portionUnit;
  final Value<double?> portionWeightGramsPerUnit;
  final Value<String?> portionWeightUnit;
  final Value<bool?> portionWeightIsEstimate;
  final Value<String?> portionWeightSourceUrl;
  final Value<String?> portionWeightSourceTitle;
  final Value<DateTime?> portionWeightSourceRetrievedAt;
  const LogEntriesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.foodName = const Value.absent(),
    this.grams = const Value.absent(),
    this.kcal = const Value.absent(),
    this.protein = const Value.absent(),
    this.carb = const Value.absent(),
    this.fat = const Value.absent(),
    this.fibre = const Value.absent(),
    this.source = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.portionQuantity = const Value.absent(),
    this.portionUnit = const Value.absent(),
    this.portionWeightGramsPerUnit = const Value.absent(),
    this.portionWeightUnit = const Value.absent(),
    this.portionWeightIsEstimate = const Value.absent(),
    this.portionWeightSourceUrl = const Value.absent(),
    this.portionWeightSourceTitle = const Value.absent(),
    this.portionWeightSourceRetrievedAt = const Value.absent(),
  });
  LogEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String date,
    required String foodName,
    required double grams,
    required double kcal,
    required double protein,
    required double carb,
    required double fat,
    this.fibre = const Value.absent(),
    required String source,
    this.recipeId = const Value.absent(),
    this.portionQuantity = const Value.absent(),
    this.portionUnit = const Value.absent(),
    this.portionWeightGramsPerUnit = const Value.absent(),
    this.portionWeightUnit = const Value.absent(),
    this.portionWeightIsEstimate = const Value.absent(),
    this.portionWeightSourceUrl = const Value.absent(),
    this.portionWeightSourceTitle = const Value.absent(),
    this.portionWeightSourceRetrievedAt = const Value.absent(),
  }) : date = Value(date),
       foodName = Value(foodName),
       grams = Value(grams),
       kcal = Value(kcal),
       protein = Value(protein),
       carb = Value(carb),
       fat = Value(fat),
       source = Value(source);
  static Insertable<LogEntry> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<String>? foodName,
    Expression<double>? grams,
    Expression<double>? kcal,
    Expression<double>? protein,
    Expression<double>? carb,
    Expression<double>? fat,
    Expression<double>? fibre,
    Expression<String>? source,
    Expression<int>? recipeId,
    Expression<double>? portionQuantity,
    Expression<String>? portionUnit,
    Expression<double>? portionWeightGramsPerUnit,
    Expression<String>? portionWeightUnit,
    Expression<bool>? portionWeightIsEstimate,
    Expression<String>? portionWeightSourceUrl,
    Expression<String>? portionWeightSourceTitle,
    Expression<DateTime>? portionWeightSourceRetrievedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (foodName != null) 'food_name': foodName,
      if (grams != null) 'grams': grams,
      if (kcal != null) 'kcal': kcal,
      if (protein != null) 'protein': protein,
      if (carb != null) 'carb': carb,
      if (fat != null) 'fat': fat,
      if (fibre != null) 'fibre': fibre,
      if (source != null) 'source': source,
      if (recipeId != null) 'recipe_id': recipeId,
      if (portionQuantity != null) 'portion_quantity': portionQuantity,
      if (portionUnit != null) 'portion_unit': portionUnit,
      if (portionWeightGramsPerUnit != null)
        'portion_weight_grams_per_unit': portionWeightGramsPerUnit,
      if (portionWeightUnit != null) 'portion_weight_unit': portionWeightUnit,
      if (portionWeightIsEstimate != null)
        'portion_weight_is_estimate': portionWeightIsEstimate,
      if (portionWeightSourceUrl != null)
        'portion_weight_source_url': portionWeightSourceUrl,
      if (portionWeightSourceTitle != null)
        'portion_weight_source_title': portionWeightSourceTitle,
      if (portionWeightSourceRetrievedAt != null)
        'portion_weight_source_retrieved_at': portionWeightSourceRetrievedAt,
    });
  }

  LogEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? date,
    Value<String>? foodName,
    Value<double>? grams,
    Value<double>? kcal,
    Value<double>? protein,
    Value<double>? carb,
    Value<double>? fat,
    Value<double?>? fibre,
    Value<String>? source,
    Value<int?>? recipeId,
    Value<double?>? portionQuantity,
    Value<String?>? portionUnit,
    Value<double?>? portionWeightGramsPerUnit,
    Value<String?>? portionWeightUnit,
    Value<bool?>? portionWeightIsEstimate,
    Value<String?>? portionWeightSourceUrl,
    Value<String?>? portionWeightSourceTitle,
    Value<DateTime?>? portionWeightSourceRetrievedAt,
  }) {
    return LogEntriesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      foodName: foodName ?? this.foodName,
      grams: grams ?? this.grams,
      kcal: kcal ?? this.kcal,
      protein: protein ?? this.protein,
      carb: carb ?? this.carb,
      fat: fat ?? this.fat,
      fibre: fibre ?? this.fibre,
      source: source ?? this.source,
      recipeId: recipeId ?? this.recipeId,
      portionQuantity: portionQuantity ?? this.portionQuantity,
      portionUnit: portionUnit ?? this.portionUnit,
      portionWeightGramsPerUnit:
          portionWeightGramsPerUnit ?? this.portionWeightGramsPerUnit,
      portionWeightUnit: portionWeightUnit ?? this.portionWeightUnit,
      portionWeightIsEstimate:
          portionWeightIsEstimate ?? this.portionWeightIsEstimate,
      portionWeightSourceUrl:
          portionWeightSourceUrl ?? this.portionWeightSourceUrl,
      portionWeightSourceTitle:
          portionWeightSourceTitle ?? this.portionWeightSourceTitle,
      portionWeightSourceRetrievedAt:
          portionWeightSourceRetrievedAt ?? this.portionWeightSourceRetrievedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (foodName.present) {
      map['food_name'] = Variable<String>(foodName.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<double>(kcal.value);
    }
    if (protein.present) {
      map['protein'] = Variable<double>(protein.value);
    }
    if (carb.present) {
      map['carb'] = Variable<double>(carb.value);
    }
    if (fat.present) {
      map['fat'] = Variable<double>(fat.value);
    }
    if (fibre.present) {
      map['fibre'] = Variable<double>(fibre.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<int>(recipeId.value);
    }
    if (portionQuantity.present) {
      map['portion_quantity'] = Variable<double>(portionQuantity.value);
    }
    if (portionUnit.present) {
      map['portion_unit'] = Variable<String>(portionUnit.value);
    }
    if (portionWeightGramsPerUnit.present) {
      map['portion_weight_grams_per_unit'] = Variable<double>(
        portionWeightGramsPerUnit.value,
      );
    }
    if (portionWeightUnit.present) {
      map['portion_weight_unit'] = Variable<String>(portionWeightUnit.value);
    }
    if (portionWeightIsEstimate.present) {
      map['portion_weight_is_estimate'] = Variable<bool>(
        portionWeightIsEstimate.value,
      );
    }
    if (portionWeightSourceUrl.present) {
      map['portion_weight_source_url'] = Variable<String>(
        portionWeightSourceUrl.value,
      );
    }
    if (portionWeightSourceTitle.present) {
      map['portion_weight_source_title'] = Variable<String>(
        portionWeightSourceTitle.value,
      );
    }
    if (portionWeightSourceRetrievedAt.present) {
      map['portion_weight_source_retrieved_at'] = Variable<DateTime>(
        portionWeightSourceRetrievedAt.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LogEntriesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('foodName: $foodName, ')
          ..write('grams: $grams, ')
          ..write('kcal: $kcal, ')
          ..write('protein: $protein, ')
          ..write('carb: $carb, ')
          ..write('fat: $fat, ')
          ..write('fibre: $fibre, ')
          ..write('source: $source, ')
          ..write('recipeId: $recipeId, ')
          ..write('portionQuantity: $portionQuantity, ')
          ..write('portionUnit: $portionUnit, ')
          ..write('portionWeightGramsPerUnit: $portionWeightGramsPerUnit, ')
          ..write('portionWeightUnit: $portionWeightUnit, ')
          ..write('portionWeightIsEstimate: $portionWeightIsEstimate, ')
          ..write('portionWeightSourceUrl: $portionWeightSourceUrl, ')
          ..write('portionWeightSourceTitle: $portionWeightSourceTitle, ')
          ..write(
            'portionWeightSourceRetrievedAt: $portionWeightSourceRetrievedAt',
          )
          ..write(')'))
        .toString();
  }
}

class $DailyTargetsTableTable extends DailyTargetsTable
    with TableInfo<$DailyTargetsTableTable, DailyTargetsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyTargetsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<double> kcal = GeneratedColumn<double>(
    'kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinMeta = const VerificationMeta(
    'protein',
  );
  @override
  late final GeneratedColumn<double> protein = GeneratedColumn<double>(
    'protein',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbMeta = const VerificationMeta('carb');
  @override
  late final GeneratedColumn<double> carb = GeneratedColumn<double>(
    'carb',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatMeta = const VerificationMeta('fat');
  @override
  late final GeneratedColumn<double> fat = GeneratedColumn<double>(
    'fat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [scope, kcal, protein, carb, fat];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_targets';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyTargetsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('kcal')) {
      context.handle(
        _kcalMeta,
        kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta),
      );
    } else if (isInserting) {
      context.missing(_kcalMeta);
    }
    if (data.containsKey('protein')) {
      context.handle(
        _proteinMeta,
        protein.isAcceptableOrUnknown(data['protein']!, _proteinMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinMeta);
    }
    if (data.containsKey('carb')) {
      context.handle(
        _carbMeta,
        carb.isAcceptableOrUnknown(data['carb']!, _carbMeta),
      );
    } else if (isInserting) {
      context.missing(_carbMeta);
    }
    if (data.containsKey('fat')) {
      context.handle(
        _fatMeta,
        fat.isAcceptableOrUnknown(data['fat']!, _fatMeta),
      );
    } else if (isInserting) {
      context.missing(_fatMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scope};
  @override
  DailyTargetsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyTargetsTableData(
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      kcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal'],
      )!,
      protein: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein'],
      )!,
      carb: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carb'],
      )!,
      fat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat'],
      )!,
    );
  }

  @override
  $DailyTargetsTableTable createAlias(String alias) {
    return $DailyTargetsTableTable(attachedDatabase, alias);
  }
}

class DailyTargetsTableData extends DataClass
    implements Insertable<DailyTargetsTableData> {
  final String scope;
  final double kcal;
  final double protein;
  final double carb;
  final double fat;
  const DailyTargetsTableData({
    required this.scope,
    required this.kcal,
    required this.protein,
    required this.carb,
    required this.fat,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['scope'] = Variable<String>(scope);
    map['kcal'] = Variable<double>(kcal);
    map['protein'] = Variable<double>(protein);
    map['carb'] = Variable<double>(carb);
    map['fat'] = Variable<double>(fat);
    return map;
  }

  DailyTargetsTableCompanion toCompanion(bool nullToAbsent) {
    return DailyTargetsTableCompanion(
      scope: Value(scope),
      kcal: Value(kcal),
      protein: Value(protein),
      carb: Value(carb),
      fat: Value(fat),
    );
  }

  factory DailyTargetsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyTargetsTableData(
      scope: serializer.fromJson<String>(json['scope']),
      kcal: serializer.fromJson<double>(json['kcal']),
      protein: serializer.fromJson<double>(json['protein']),
      carb: serializer.fromJson<double>(json['carb']),
      fat: serializer.fromJson<double>(json['fat']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scope': serializer.toJson<String>(scope),
      'kcal': serializer.toJson<double>(kcal),
      'protein': serializer.toJson<double>(protein),
      'carb': serializer.toJson<double>(carb),
      'fat': serializer.toJson<double>(fat),
    };
  }

  DailyTargetsTableData copyWith({
    String? scope,
    double? kcal,
    double? protein,
    double? carb,
    double? fat,
  }) => DailyTargetsTableData(
    scope: scope ?? this.scope,
    kcal: kcal ?? this.kcal,
    protein: protein ?? this.protein,
    carb: carb ?? this.carb,
    fat: fat ?? this.fat,
  );
  DailyTargetsTableData copyWithCompanion(DailyTargetsTableCompanion data) {
    return DailyTargetsTableData(
      scope: data.scope.present ? data.scope.value : this.scope,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      protein: data.protein.present ? data.protein.value : this.protein,
      carb: data.carb.present ? data.carb.value : this.carb,
      fat: data.fat.present ? data.fat.value : this.fat,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyTargetsTableData(')
          ..write('scope: $scope, ')
          ..write('kcal: $kcal, ')
          ..write('protein: $protein, ')
          ..write('carb: $carb, ')
          ..write('fat: $fat')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(scope, kcal, protein, carb, fat);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyTargetsTableData &&
          other.scope == this.scope &&
          other.kcal == this.kcal &&
          other.protein == this.protein &&
          other.carb == this.carb &&
          other.fat == this.fat);
}

class DailyTargetsTableCompanion
    extends UpdateCompanion<DailyTargetsTableData> {
  final Value<String> scope;
  final Value<double> kcal;
  final Value<double> protein;
  final Value<double> carb;
  final Value<double> fat;
  final Value<int> rowid;
  const DailyTargetsTableCompanion({
    this.scope = const Value.absent(),
    this.kcal = const Value.absent(),
    this.protein = const Value.absent(),
    this.carb = const Value.absent(),
    this.fat = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyTargetsTableCompanion.insert({
    required String scope,
    required double kcal,
    required double protein,
    required double carb,
    required double fat,
    this.rowid = const Value.absent(),
  }) : scope = Value(scope),
       kcal = Value(kcal),
       protein = Value(protein),
       carb = Value(carb),
       fat = Value(fat);
  static Insertable<DailyTargetsTableData> custom({
    Expression<String>? scope,
    Expression<double>? kcal,
    Expression<double>? protein,
    Expression<double>? carb,
    Expression<double>? fat,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scope != null) 'scope': scope,
      if (kcal != null) 'kcal': kcal,
      if (protein != null) 'protein': protein,
      if (carb != null) 'carb': carb,
      if (fat != null) 'fat': fat,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyTargetsTableCompanion copyWith({
    Value<String>? scope,
    Value<double>? kcal,
    Value<double>? protein,
    Value<double>? carb,
    Value<double>? fat,
    Value<int>? rowid,
  }) {
    return DailyTargetsTableCompanion(
      scope: scope ?? this.scope,
      kcal: kcal ?? this.kcal,
      protein: protein ?? this.protein,
      carb: carb ?? this.carb,
      fat: fat ?? this.fat,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<double>(kcal.value);
    }
    if (protein.present) {
      map['protein'] = Variable<double>(protein.value);
    }
    if (carb.present) {
      map['carb'] = Variable<double>(carb.value);
    }
    if (fat.present) {
      map['fat'] = Variable<double>(fat.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyTargetsTableCompanion(')
          ..write('scope: $scope, ')
          ..write('kcal: $kcal, ')
          ..write('protein: $protein, ')
          ..write('carb: $carb, ')
          ..write('fat: $fat, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AdaptiveTargetsTable extends AdaptiveTargets
    with TableInfo<$AdaptiveTargetsTable, AdaptiveTarget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdaptiveTargetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _effectiveFromMeta = const VerificationMeta(
    'effectiveFrom',
  );
  @override
  late final GeneratedColumn<String> effectiveFrom = GeneratedColumn<String>(
    'effective_from',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _calculatedThroughMeta = const VerificationMeta(
    'calculatedThrough',
  );
  @override
  late final GeneratedColumn<String> calculatedThrough =
      GeneratedColumn<String>(
        'calculated_through',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<double> kcal = GeneratedColumn<double>(
    'kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinMeta = const VerificationMeta(
    'protein',
  );
  @override
  late final GeneratedColumn<double> protein = GeneratedColumn<double>(
    'protein',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbMeta = const VerificationMeta('carb');
  @override
  late final GeneratedColumn<double> carb = GeneratedColumn<double>(
    'carb',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatMeta = const VerificationMeta('fat');
  @override
  late final GeneratedColumn<double> fat = GeneratedColumn<double>(
    'fat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _windowStartMeta = const VerificationMeta(
    'windowStart',
  );
  @override
  late final GeneratedColumn<String> windowStart = GeneratedColumn<String>(
    'window_start',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qualifiedIntakeDaysMeta =
      const VerificationMeta('qualifiedIntakeDays');
  @override
  late final GeneratedColumn<int> qualifiedIntakeDays = GeneratedColumn<int>(
    'qualified_intake_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightObservationCountMeta =
      const VerificationMeta('weightObservationCount');
  @override
  late final GeneratedColumn<int> weightObservationCount = GeneratedColumn<int>(
    'weight_observation_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _estimatedMaintenanceKcalMeta =
      const VerificationMeta('estimatedMaintenanceKcal');
  @override
  late final GeneratedColumn<double> estimatedMaintenanceKcal =
      GeneratedColumn<double>(
        'estimated_maintenance_kcal',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _appliedAdjustmentKcalMeta =
      const VerificationMeta('appliedAdjustmentKcal');
  @override
  late final GeneratedColumn<double> appliedAdjustmentKcal =
      GeneratedColumn<double>(
        'applied_adjustment_kcal',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalMeta = const VerificationMeta('goal');
  @override
  late final GeneratedColumn<String> goal = GeneratedColumn<String>(
    'goal',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    effectiveFrom,
    calculatedThrough,
    kcal,
    protein,
    carb,
    fat,
    windowStart,
    qualifiedIntakeDays,
    weightObservationCount,
    estimatedMaintenanceKcal,
    appliedAdjustmentKcal,
    reason,
    goal,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'adaptive_targets';
  @override
  VerificationContext validateIntegrity(
    Insertable<AdaptiveTarget> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('effective_from')) {
      context.handle(
        _effectiveFromMeta,
        effectiveFrom.isAcceptableOrUnknown(
          data['effective_from']!,
          _effectiveFromMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effectiveFromMeta);
    }
    if (data.containsKey('calculated_through')) {
      context.handle(
        _calculatedThroughMeta,
        calculatedThrough.isAcceptableOrUnknown(
          data['calculated_through']!,
          _calculatedThroughMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_calculatedThroughMeta);
    }
    if (data.containsKey('kcal')) {
      context.handle(
        _kcalMeta,
        kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta),
      );
    } else if (isInserting) {
      context.missing(_kcalMeta);
    }
    if (data.containsKey('protein')) {
      context.handle(
        _proteinMeta,
        protein.isAcceptableOrUnknown(data['protein']!, _proteinMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinMeta);
    }
    if (data.containsKey('carb')) {
      context.handle(
        _carbMeta,
        carb.isAcceptableOrUnknown(data['carb']!, _carbMeta),
      );
    } else if (isInserting) {
      context.missing(_carbMeta);
    }
    if (data.containsKey('fat')) {
      context.handle(
        _fatMeta,
        fat.isAcceptableOrUnknown(data['fat']!, _fatMeta),
      );
    } else if (isInserting) {
      context.missing(_fatMeta);
    }
    if (data.containsKey('window_start')) {
      context.handle(
        _windowStartMeta,
        windowStart.isAcceptableOrUnknown(
          data['window_start']!,
          _windowStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_windowStartMeta);
    }
    if (data.containsKey('qualified_intake_days')) {
      context.handle(
        _qualifiedIntakeDaysMeta,
        qualifiedIntakeDays.isAcceptableOrUnknown(
          data['qualified_intake_days']!,
          _qualifiedIntakeDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_qualifiedIntakeDaysMeta);
    }
    if (data.containsKey('weight_observation_count')) {
      context.handle(
        _weightObservationCountMeta,
        weightObservationCount.isAcceptableOrUnknown(
          data['weight_observation_count']!,
          _weightObservationCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_weightObservationCountMeta);
    }
    if (data.containsKey('estimated_maintenance_kcal')) {
      context.handle(
        _estimatedMaintenanceKcalMeta,
        estimatedMaintenanceKcal.isAcceptableOrUnknown(
          data['estimated_maintenance_kcal']!,
          _estimatedMaintenanceKcalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_estimatedMaintenanceKcalMeta);
    }
    if (data.containsKey('applied_adjustment_kcal')) {
      context.handle(
        _appliedAdjustmentKcalMeta,
        appliedAdjustmentKcal.isAcceptableOrUnknown(
          data['applied_adjustment_kcal']!,
          _appliedAdjustmentKcalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_appliedAdjustmentKcalMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('goal')) {
      context.handle(
        _goalMeta,
        goal.isAcceptableOrUnknown(data['goal']!, _goalMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AdaptiveTarget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdaptiveTarget(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      effectiveFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}effective_from'],
      )!,
      calculatedThrough: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calculated_through'],
      )!,
      kcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal'],
      )!,
      protein: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein'],
      )!,
      carb: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carb'],
      )!,
      fat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat'],
      )!,
      windowStart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}window_start'],
      )!,
      qualifiedIntakeDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qualified_intake_days'],
      )!,
      weightObservationCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weight_observation_count'],
      )!,
      estimatedMaintenanceKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}estimated_maintenance_kcal'],
      )!,
      appliedAdjustmentKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}applied_adjustment_kcal'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      goal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AdaptiveTargetsTable createAlias(String alias) {
    return $AdaptiveTargetsTable(attachedDatabase, alias);
  }
}

class AdaptiveTarget extends DataClass implements Insertable<AdaptiveTarget> {
  final int id;
  final String effectiveFrom;
  final String calculatedThrough;
  final double kcal;
  final double protein;
  final double carb;
  final double fat;
  final String windowStart;
  final int qualifiedIntakeDays;
  final int weightObservationCount;
  final double estimatedMaintenanceKcal;
  final double appliedAdjustmentKcal;
  final String reason;
  final String? goal;
  final DateTime createdAt;
  const AdaptiveTarget({
    required this.id,
    required this.effectiveFrom,
    required this.calculatedThrough,
    required this.kcal,
    required this.protein,
    required this.carb,
    required this.fat,
    required this.windowStart,
    required this.qualifiedIntakeDays,
    required this.weightObservationCount,
    required this.estimatedMaintenanceKcal,
    required this.appliedAdjustmentKcal,
    required this.reason,
    this.goal,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['effective_from'] = Variable<String>(effectiveFrom);
    map['calculated_through'] = Variable<String>(calculatedThrough);
    map['kcal'] = Variable<double>(kcal);
    map['protein'] = Variable<double>(protein);
    map['carb'] = Variable<double>(carb);
    map['fat'] = Variable<double>(fat);
    map['window_start'] = Variable<String>(windowStart);
    map['qualified_intake_days'] = Variable<int>(qualifiedIntakeDays);
    map['weight_observation_count'] = Variable<int>(weightObservationCount);
    map['estimated_maintenance_kcal'] = Variable<double>(
      estimatedMaintenanceKcal,
    );
    map['applied_adjustment_kcal'] = Variable<double>(appliedAdjustmentKcal);
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || goal != null) {
      map['goal'] = Variable<String>(goal);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AdaptiveTargetsCompanion toCompanion(bool nullToAbsent) {
    return AdaptiveTargetsCompanion(
      id: Value(id),
      effectiveFrom: Value(effectiveFrom),
      calculatedThrough: Value(calculatedThrough),
      kcal: Value(kcal),
      protein: Value(protein),
      carb: Value(carb),
      fat: Value(fat),
      windowStart: Value(windowStart),
      qualifiedIntakeDays: Value(qualifiedIntakeDays),
      weightObservationCount: Value(weightObservationCount),
      estimatedMaintenanceKcal: Value(estimatedMaintenanceKcal),
      appliedAdjustmentKcal: Value(appliedAdjustmentKcal),
      reason: Value(reason),
      goal: goal == null && nullToAbsent ? const Value.absent() : Value(goal),
      createdAt: Value(createdAt),
    );
  }

  factory AdaptiveTarget.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdaptiveTarget(
      id: serializer.fromJson<int>(json['id']),
      effectiveFrom: serializer.fromJson<String>(json['effectiveFrom']),
      calculatedThrough: serializer.fromJson<String>(json['calculatedThrough']),
      kcal: serializer.fromJson<double>(json['kcal']),
      protein: serializer.fromJson<double>(json['protein']),
      carb: serializer.fromJson<double>(json['carb']),
      fat: serializer.fromJson<double>(json['fat']),
      windowStart: serializer.fromJson<String>(json['windowStart']),
      qualifiedIntakeDays: serializer.fromJson<int>(
        json['qualifiedIntakeDays'],
      ),
      weightObservationCount: serializer.fromJson<int>(
        json['weightObservationCount'],
      ),
      estimatedMaintenanceKcal: serializer.fromJson<double>(
        json['estimatedMaintenanceKcal'],
      ),
      appliedAdjustmentKcal: serializer.fromJson<double>(
        json['appliedAdjustmentKcal'],
      ),
      reason: serializer.fromJson<String>(json['reason']),
      goal: serializer.fromJson<String?>(json['goal']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'effectiveFrom': serializer.toJson<String>(effectiveFrom),
      'calculatedThrough': serializer.toJson<String>(calculatedThrough),
      'kcal': serializer.toJson<double>(kcal),
      'protein': serializer.toJson<double>(protein),
      'carb': serializer.toJson<double>(carb),
      'fat': serializer.toJson<double>(fat),
      'windowStart': serializer.toJson<String>(windowStart),
      'qualifiedIntakeDays': serializer.toJson<int>(qualifiedIntakeDays),
      'weightObservationCount': serializer.toJson<int>(weightObservationCount),
      'estimatedMaintenanceKcal': serializer.toJson<double>(
        estimatedMaintenanceKcal,
      ),
      'appliedAdjustmentKcal': serializer.toJson<double>(appliedAdjustmentKcal),
      'reason': serializer.toJson<String>(reason),
      'goal': serializer.toJson<String?>(goal),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AdaptiveTarget copyWith({
    int? id,
    String? effectiveFrom,
    String? calculatedThrough,
    double? kcal,
    double? protein,
    double? carb,
    double? fat,
    String? windowStart,
    int? qualifiedIntakeDays,
    int? weightObservationCount,
    double? estimatedMaintenanceKcal,
    double? appliedAdjustmentKcal,
    String? reason,
    Value<String?> goal = const Value.absent(),
    DateTime? createdAt,
  }) => AdaptiveTarget(
    id: id ?? this.id,
    effectiveFrom: effectiveFrom ?? this.effectiveFrom,
    calculatedThrough: calculatedThrough ?? this.calculatedThrough,
    kcal: kcal ?? this.kcal,
    protein: protein ?? this.protein,
    carb: carb ?? this.carb,
    fat: fat ?? this.fat,
    windowStart: windowStart ?? this.windowStart,
    qualifiedIntakeDays: qualifiedIntakeDays ?? this.qualifiedIntakeDays,
    weightObservationCount:
        weightObservationCount ?? this.weightObservationCount,
    estimatedMaintenanceKcal:
        estimatedMaintenanceKcal ?? this.estimatedMaintenanceKcal,
    appliedAdjustmentKcal: appliedAdjustmentKcal ?? this.appliedAdjustmentKcal,
    reason: reason ?? this.reason,
    goal: goal.present ? goal.value : this.goal,
    createdAt: createdAt ?? this.createdAt,
  );
  AdaptiveTarget copyWithCompanion(AdaptiveTargetsCompanion data) {
    return AdaptiveTarget(
      id: data.id.present ? data.id.value : this.id,
      effectiveFrom: data.effectiveFrom.present
          ? data.effectiveFrom.value
          : this.effectiveFrom,
      calculatedThrough: data.calculatedThrough.present
          ? data.calculatedThrough.value
          : this.calculatedThrough,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      protein: data.protein.present ? data.protein.value : this.protein,
      carb: data.carb.present ? data.carb.value : this.carb,
      fat: data.fat.present ? data.fat.value : this.fat,
      windowStart: data.windowStart.present
          ? data.windowStart.value
          : this.windowStart,
      qualifiedIntakeDays: data.qualifiedIntakeDays.present
          ? data.qualifiedIntakeDays.value
          : this.qualifiedIntakeDays,
      weightObservationCount: data.weightObservationCount.present
          ? data.weightObservationCount.value
          : this.weightObservationCount,
      estimatedMaintenanceKcal: data.estimatedMaintenanceKcal.present
          ? data.estimatedMaintenanceKcal.value
          : this.estimatedMaintenanceKcal,
      appliedAdjustmentKcal: data.appliedAdjustmentKcal.present
          ? data.appliedAdjustmentKcal.value
          : this.appliedAdjustmentKcal,
      reason: data.reason.present ? data.reason.value : this.reason,
      goal: data.goal.present ? data.goal.value : this.goal,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdaptiveTarget(')
          ..write('id: $id, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('calculatedThrough: $calculatedThrough, ')
          ..write('kcal: $kcal, ')
          ..write('protein: $protein, ')
          ..write('carb: $carb, ')
          ..write('fat: $fat, ')
          ..write('windowStart: $windowStart, ')
          ..write('qualifiedIntakeDays: $qualifiedIntakeDays, ')
          ..write('weightObservationCount: $weightObservationCount, ')
          ..write('estimatedMaintenanceKcal: $estimatedMaintenanceKcal, ')
          ..write('appliedAdjustmentKcal: $appliedAdjustmentKcal, ')
          ..write('reason: $reason, ')
          ..write('goal: $goal, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    effectiveFrom,
    calculatedThrough,
    kcal,
    protein,
    carb,
    fat,
    windowStart,
    qualifiedIntakeDays,
    weightObservationCount,
    estimatedMaintenanceKcal,
    appliedAdjustmentKcal,
    reason,
    goal,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdaptiveTarget &&
          other.id == this.id &&
          other.effectiveFrom == this.effectiveFrom &&
          other.calculatedThrough == this.calculatedThrough &&
          other.kcal == this.kcal &&
          other.protein == this.protein &&
          other.carb == this.carb &&
          other.fat == this.fat &&
          other.windowStart == this.windowStart &&
          other.qualifiedIntakeDays == this.qualifiedIntakeDays &&
          other.weightObservationCount == this.weightObservationCount &&
          other.estimatedMaintenanceKcal == this.estimatedMaintenanceKcal &&
          other.appliedAdjustmentKcal == this.appliedAdjustmentKcal &&
          other.reason == this.reason &&
          other.goal == this.goal &&
          other.createdAt == this.createdAt);
}

class AdaptiveTargetsCompanion extends UpdateCompanion<AdaptiveTarget> {
  final Value<int> id;
  final Value<String> effectiveFrom;
  final Value<String> calculatedThrough;
  final Value<double> kcal;
  final Value<double> protein;
  final Value<double> carb;
  final Value<double> fat;
  final Value<String> windowStart;
  final Value<int> qualifiedIntakeDays;
  final Value<int> weightObservationCount;
  final Value<double> estimatedMaintenanceKcal;
  final Value<double> appliedAdjustmentKcal;
  final Value<String> reason;
  final Value<String?> goal;
  final Value<DateTime> createdAt;
  const AdaptiveTargetsCompanion({
    this.id = const Value.absent(),
    this.effectiveFrom = const Value.absent(),
    this.calculatedThrough = const Value.absent(),
    this.kcal = const Value.absent(),
    this.protein = const Value.absent(),
    this.carb = const Value.absent(),
    this.fat = const Value.absent(),
    this.windowStart = const Value.absent(),
    this.qualifiedIntakeDays = const Value.absent(),
    this.weightObservationCount = const Value.absent(),
    this.estimatedMaintenanceKcal = const Value.absent(),
    this.appliedAdjustmentKcal = const Value.absent(),
    this.reason = const Value.absent(),
    this.goal = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AdaptiveTargetsCompanion.insert({
    this.id = const Value.absent(),
    required String effectiveFrom,
    required String calculatedThrough,
    required double kcal,
    required double protein,
    required double carb,
    required double fat,
    required String windowStart,
    required int qualifiedIntakeDays,
    required int weightObservationCount,
    required double estimatedMaintenanceKcal,
    required double appliedAdjustmentKcal,
    required String reason,
    this.goal = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : effectiveFrom = Value(effectiveFrom),
       calculatedThrough = Value(calculatedThrough),
       kcal = Value(kcal),
       protein = Value(protein),
       carb = Value(carb),
       fat = Value(fat),
       windowStart = Value(windowStart),
       qualifiedIntakeDays = Value(qualifiedIntakeDays),
       weightObservationCount = Value(weightObservationCount),
       estimatedMaintenanceKcal = Value(estimatedMaintenanceKcal),
       appliedAdjustmentKcal = Value(appliedAdjustmentKcal),
       reason = Value(reason);
  static Insertable<AdaptiveTarget> custom({
    Expression<int>? id,
    Expression<String>? effectiveFrom,
    Expression<String>? calculatedThrough,
    Expression<double>? kcal,
    Expression<double>? protein,
    Expression<double>? carb,
    Expression<double>? fat,
    Expression<String>? windowStart,
    Expression<int>? qualifiedIntakeDays,
    Expression<int>? weightObservationCount,
    Expression<double>? estimatedMaintenanceKcal,
    Expression<double>? appliedAdjustmentKcal,
    Expression<String>? reason,
    Expression<String>? goal,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (effectiveFrom != null) 'effective_from': effectiveFrom,
      if (calculatedThrough != null) 'calculated_through': calculatedThrough,
      if (kcal != null) 'kcal': kcal,
      if (protein != null) 'protein': protein,
      if (carb != null) 'carb': carb,
      if (fat != null) 'fat': fat,
      if (windowStart != null) 'window_start': windowStart,
      if (qualifiedIntakeDays != null)
        'qualified_intake_days': qualifiedIntakeDays,
      if (weightObservationCount != null)
        'weight_observation_count': weightObservationCount,
      if (estimatedMaintenanceKcal != null)
        'estimated_maintenance_kcal': estimatedMaintenanceKcal,
      if (appliedAdjustmentKcal != null)
        'applied_adjustment_kcal': appliedAdjustmentKcal,
      if (reason != null) 'reason': reason,
      if (goal != null) 'goal': goal,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AdaptiveTargetsCompanion copyWith({
    Value<int>? id,
    Value<String>? effectiveFrom,
    Value<String>? calculatedThrough,
    Value<double>? kcal,
    Value<double>? protein,
    Value<double>? carb,
    Value<double>? fat,
    Value<String>? windowStart,
    Value<int>? qualifiedIntakeDays,
    Value<int>? weightObservationCount,
    Value<double>? estimatedMaintenanceKcal,
    Value<double>? appliedAdjustmentKcal,
    Value<String>? reason,
    Value<String?>? goal,
    Value<DateTime>? createdAt,
  }) {
    return AdaptiveTargetsCompanion(
      id: id ?? this.id,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      calculatedThrough: calculatedThrough ?? this.calculatedThrough,
      kcal: kcal ?? this.kcal,
      protein: protein ?? this.protein,
      carb: carb ?? this.carb,
      fat: fat ?? this.fat,
      windowStart: windowStart ?? this.windowStart,
      qualifiedIntakeDays: qualifiedIntakeDays ?? this.qualifiedIntakeDays,
      weightObservationCount:
          weightObservationCount ?? this.weightObservationCount,
      estimatedMaintenanceKcal:
          estimatedMaintenanceKcal ?? this.estimatedMaintenanceKcal,
      appliedAdjustmentKcal:
          appliedAdjustmentKcal ?? this.appliedAdjustmentKcal,
      reason: reason ?? this.reason,
      goal: goal ?? this.goal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (effectiveFrom.present) {
      map['effective_from'] = Variable<String>(effectiveFrom.value);
    }
    if (calculatedThrough.present) {
      map['calculated_through'] = Variable<String>(calculatedThrough.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<double>(kcal.value);
    }
    if (protein.present) {
      map['protein'] = Variable<double>(protein.value);
    }
    if (carb.present) {
      map['carb'] = Variable<double>(carb.value);
    }
    if (fat.present) {
      map['fat'] = Variable<double>(fat.value);
    }
    if (windowStart.present) {
      map['window_start'] = Variable<String>(windowStart.value);
    }
    if (qualifiedIntakeDays.present) {
      map['qualified_intake_days'] = Variable<int>(qualifiedIntakeDays.value);
    }
    if (weightObservationCount.present) {
      map['weight_observation_count'] = Variable<int>(
        weightObservationCount.value,
      );
    }
    if (estimatedMaintenanceKcal.present) {
      map['estimated_maintenance_kcal'] = Variable<double>(
        estimatedMaintenanceKcal.value,
      );
    }
    if (appliedAdjustmentKcal.present) {
      map['applied_adjustment_kcal'] = Variable<double>(
        appliedAdjustmentKcal.value,
      );
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (goal.present) {
      map['goal'] = Variable<String>(goal.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdaptiveTargetsCompanion(')
          ..write('id: $id, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('calculatedThrough: $calculatedThrough, ')
          ..write('kcal: $kcal, ')
          ..write('protein: $protein, ')
          ..write('carb: $carb, ')
          ..write('fat: $fat, ')
          ..write('windowStart: $windowStart, ')
          ..write('qualifiedIntakeDays: $qualifiedIntakeDays, ')
          ..write('weightObservationCount: $weightObservationCount, ')
          ..write('estimatedMaintenanceKcal: $estimatedMaintenanceKcal, ')
          ..write('appliedAdjustmentKcal: $appliedAdjustmentKcal, ')
          ..write('reason: $reason, ')
          ..write('goal: $goal, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroceryItemsTable extends GroceryItems
    with TableInfo<$GroceryItemsTable, GroceryItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroceryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  @override
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _checkedMeta = const VerificationMeta(
    'checked',
  );
  @override
  late final GeneratedColumn<bool> checked = GeneratedColumn<bool>(
    'checked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("checked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, detail, checked, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grocery_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<GroceryItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('detail')) {
      context.handle(
        _detailMeta,
        detail.isAcceptableOrUnknown(data['detail']!, _detailMeta),
      );
    }
    if (data.containsKey('checked')) {
      context.handle(
        _checkedMeta,
        checked.isAcceptableOrUnknown(data['checked']!, _checkedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GroceryItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroceryItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      detail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail'],
      ),
      checked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}checked'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $GroceryItemsTable createAlias(String alias) {
    return $GroceryItemsTable(attachedDatabase, alias);
  }
}

class GroceryItem extends DataClass implements Insertable<GroceryItem> {
  final int id;
  final String name;
  final String? detail;
  final bool checked;
  final DateTime createdAt;
  const GroceryItem({
    required this.id,
    required this.name,
    this.detail,
    required this.checked,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || detail != null) {
      map['detail'] = Variable<String>(detail);
    }
    map['checked'] = Variable<bool>(checked);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GroceryItemsCompanion toCompanion(bool nullToAbsent) {
    return GroceryItemsCompanion(
      id: Value(id),
      name: Value(name),
      detail: detail == null && nullToAbsent
          ? const Value.absent()
          : Value(detail),
      checked: Value(checked),
      createdAt: Value(createdAt),
    );
  }

  factory GroceryItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroceryItem(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      detail: serializer.fromJson<String?>(json['detail']),
      checked: serializer.fromJson<bool>(json['checked']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'detail': serializer.toJson<String?>(detail),
      'checked': serializer.toJson<bool>(checked),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  GroceryItem copyWith({
    int? id,
    String? name,
    Value<String?> detail = const Value.absent(),
    bool? checked,
    DateTime? createdAt,
  }) => GroceryItem(
    id: id ?? this.id,
    name: name ?? this.name,
    detail: detail.present ? detail.value : this.detail,
    checked: checked ?? this.checked,
    createdAt: createdAt ?? this.createdAt,
  );
  GroceryItem copyWithCompanion(GroceryItemsCompanion data) {
    return GroceryItem(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      detail: data.detail.present ? data.detail.value : this.detail,
      checked: data.checked.present ? data.checked.value : this.checked,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroceryItem(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('detail: $detail, ')
          ..write('checked: $checked, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, detail, checked, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroceryItem &&
          other.id == this.id &&
          other.name == this.name &&
          other.detail == this.detail &&
          other.checked == this.checked &&
          other.createdAt == this.createdAt);
}

class GroceryItemsCompanion extends UpdateCompanion<GroceryItem> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> detail;
  final Value<bool> checked;
  final Value<DateTime> createdAt;
  const GroceryItemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.detail = const Value.absent(),
    this.checked = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  GroceryItemsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.detail = const Value.absent(),
    this.checked = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<GroceryItem> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? detail,
    Expression<bool>? checked,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (detail != null) 'detail': detail,
      if (checked != null) 'checked': checked,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  GroceryItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? detail,
    Value<bool>? checked,
    Value<DateTime>? createdAt,
  }) {
    return GroceryItemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      detail: detail ?? this.detail,
      checked: checked ?? this.checked,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    if (checked.present) {
      map['checked'] = Variable<bool>(checked.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroceryItemsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('detail: $detail, ')
          ..write('checked: $checked, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WeightEntriesTable extends WeightEntries
    with TableInfo<$WeightEntriesTable, WeightEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeightEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kgMeta = const VerificationMeta('kg');
  @override
  late final GeneratedColumn<double> kg = GeneratedColumn<double>(
    'kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, date, kg];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weight_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeightEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('kg')) {
      context.handle(_kgMeta, kg.isAcceptableOrUnknown(data['kg']!, _kgMeta));
    } else if (isInserting) {
      context.missing(_kgMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {date},
  ];
  @override
  WeightEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeightEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      kg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kg'],
      )!,
    );
  }

  @override
  $WeightEntriesTable createAlias(String alias) {
    return $WeightEntriesTable(attachedDatabase, alias);
  }
}

class WeightEntry extends DataClass implements Insertable<WeightEntry> {
  final int id;
  final String date;
  final double kg;
  const WeightEntry({required this.id, required this.date, required this.kg});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<String>(date);
    map['kg'] = Variable<double>(kg);
    return map;
  }

  WeightEntriesCompanion toCompanion(bool nullToAbsent) {
    return WeightEntriesCompanion(
      id: Value(id),
      date: Value(date),
      kg: Value(kg),
    );
  }

  factory WeightEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeightEntry(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      kg: serializer.fromJson<double>(json['kg']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(date),
      'kg': serializer.toJson<double>(kg),
    };
  }

  WeightEntry copyWith({int? id, String? date, double? kg}) => WeightEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    kg: kg ?? this.kg,
  );
  WeightEntry copyWithCompanion(WeightEntriesCompanion data) {
    return WeightEntry(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      kg: data.kg.present ? data.kg.value : this.kg,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeightEntry(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('kg: $kg')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, kg);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeightEntry &&
          other.id == this.id &&
          other.date == this.date &&
          other.kg == this.kg);
}

class WeightEntriesCompanion extends UpdateCompanion<WeightEntry> {
  final Value<int> id;
  final Value<String> date;
  final Value<double> kg;
  const WeightEntriesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.kg = const Value.absent(),
  });
  WeightEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String date,
    required double kg,
  }) : date = Value(date),
       kg = Value(kg);
  static Insertable<WeightEntry> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<double>? kg,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (kg != null) 'kg': kg,
    });
  }

  WeightEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? date,
    Value<double>? kg,
  }) {
    return WeightEntriesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      kg: kg ?? this.kg,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (kg.present) {
      map['kg'] = Variable<double>(kg.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeightEntriesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('kg: $kg')
          ..write(')'))
        .toString();
  }
}

class $ExercisesTable extends Exercises
    with TableInfo<$ExercisesTable, Exercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _primaryMuscleMeta = const VerificationMeta(
    'primaryMuscle',
  );
  @override
  late final GeneratedColumn<String> primaryMuscle = GeneratedColumn<String>(
    'primary_muscle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _secondaryMusclesMeta = const VerificationMeta(
    'secondaryMuscles',
  );
  @override
  late final GeneratedColumn<String> secondaryMuscles = GeneratedColumn<String>(
    'secondary_muscles',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _equipmentMeta = const VerificationMeta(
    'equipment',
  );
  @override
  late final GeneratedColumn<String> equipment = GeneratedColumn<String>(
    'equipment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tracksWeightMeta = const VerificationMeta(
    'tracksWeight',
  );
  @override
  late final GeneratedColumn<bool> tracksWeight = GeneratedColumn<bool>(
    'tracks_weight',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tracks_weight" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tracksRepsMeta = const VerificationMeta(
    'tracksReps',
  );
  @override
  late final GeneratedColumn<bool> tracksReps = GeneratedColumn<bool>(
    'tracks_reps',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tracks_reps" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tracksDurationMeta = const VerificationMeta(
    'tracksDuration',
  );
  @override
  late final GeneratedColumn<bool> tracksDuration = GeneratedColumn<bool>(
    'tracks_duration',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tracks_duration" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tracksDistanceMeta = const VerificationMeta(
    'tracksDistance',
  );
  @override
  late final GeneratedColumn<bool> tracksDistance = GeneratedColumn<bool>(
    'tracks_distance',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tracks_distance" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isCustomMeta = const VerificationMeta(
    'isCustom',
  );
  @override
  late final GeneratedColumn<bool> isCustom = GeneratedColumn<bool>(
    'is_custom',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_custom" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    slug,
    name,
    category,
    primaryMuscle,
    secondaryMuscles,
    equipment,
    description,
    tracksWeight,
    tracksReps,
    tracksDuration,
    tracksDistance,
    isCustom,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<Exercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('primary_muscle')) {
      context.handle(
        _primaryMuscleMeta,
        primaryMuscle.isAcceptableOrUnknown(
          data['primary_muscle']!,
          _primaryMuscleMeta,
        ),
      );
    }
    if (data.containsKey('secondary_muscles')) {
      context.handle(
        _secondaryMusclesMeta,
        secondaryMuscles.isAcceptableOrUnknown(
          data['secondary_muscles']!,
          _secondaryMusclesMeta,
        ),
      );
    }
    if (data.containsKey('equipment')) {
      context.handle(
        _equipmentMeta,
        equipment.isAcceptableOrUnknown(data['equipment']!, _equipmentMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('tracks_weight')) {
      context.handle(
        _tracksWeightMeta,
        tracksWeight.isAcceptableOrUnknown(
          data['tracks_weight']!,
          _tracksWeightMeta,
        ),
      );
    }
    if (data.containsKey('tracks_reps')) {
      context.handle(
        _tracksRepsMeta,
        tracksReps.isAcceptableOrUnknown(data['tracks_reps']!, _tracksRepsMeta),
      );
    }
    if (data.containsKey('tracks_duration')) {
      context.handle(
        _tracksDurationMeta,
        tracksDuration.isAcceptableOrUnknown(
          data['tracks_duration']!,
          _tracksDurationMeta,
        ),
      );
    }
    if (data.containsKey('tracks_distance')) {
      context.handle(
        _tracksDistanceMeta,
        tracksDistance.isAcceptableOrUnknown(
          data['tracks_distance']!,
          _tracksDistanceMeta,
        ),
      );
    }
    if (data.containsKey('is_custom')) {
      context.handle(
        _isCustomMeta,
        isCustom.isAcceptableOrUnknown(data['is_custom']!, _isCustomMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Exercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Exercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      primaryMuscle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_muscle'],
      ),
      secondaryMuscles: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secondary_muscles'],
      ),
      equipment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      tracksWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tracks_weight'],
      )!,
      tracksReps: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tracks_reps'],
      )!,
      tracksDuration: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tracks_duration'],
      )!,
      tracksDistance: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tracks_distance'],
      )!,
      isCustom: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_custom'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }
}

class Exercise extends DataClass implements Insertable<Exercise> {
  final int id;
  final String? slug;
  final String name;
  final String category;
  final String? primaryMuscle;
  final String? secondaryMuscles;
  final String? equipment;
  final String? description;
  final bool tracksWeight;
  final bool tracksReps;
  final bool tracksDuration;
  final bool tracksDistance;
  final bool isCustom;
  final DateTime createdAt;
  const Exercise({
    required this.id,
    this.slug,
    required this.name,
    required this.category,
    this.primaryMuscle,
    this.secondaryMuscles,
    this.equipment,
    this.description,
    required this.tracksWeight,
    required this.tracksReps,
    required this.tracksDuration,
    required this.tracksDistance,
    required this.isCustom,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || slug != null) {
      map['slug'] = Variable<String>(slug);
    }
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || primaryMuscle != null) {
      map['primary_muscle'] = Variable<String>(primaryMuscle);
    }
    if (!nullToAbsent || secondaryMuscles != null) {
      map['secondary_muscles'] = Variable<String>(secondaryMuscles);
    }
    if (!nullToAbsent || equipment != null) {
      map['equipment'] = Variable<String>(equipment);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['tracks_weight'] = Variable<bool>(tracksWeight);
    map['tracks_reps'] = Variable<bool>(tracksReps);
    map['tracks_duration'] = Variable<bool>(tracksDuration);
    map['tracks_distance'] = Variable<bool>(tracksDistance);
    map['is_custom'] = Variable<bool>(isCustom);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      slug: slug == null && nullToAbsent ? const Value.absent() : Value(slug),
      name: Value(name),
      category: Value(category),
      primaryMuscle: primaryMuscle == null && nullToAbsent
          ? const Value.absent()
          : Value(primaryMuscle),
      secondaryMuscles: secondaryMuscles == null && nullToAbsent
          ? const Value.absent()
          : Value(secondaryMuscles),
      equipment: equipment == null && nullToAbsent
          ? const Value.absent()
          : Value(equipment),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      tracksWeight: Value(tracksWeight),
      tracksReps: Value(tracksReps),
      tracksDuration: Value(tracksDuration),
      tracksDistance: Value(tracksDistance),
      isCustom: Value(isCustom),
      createdAt: Value(createdAt),
    );
  }

  factory Exercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Exercise(
      id: serializer.fromJson<int>(json['id']),
      slug: serializer.fromJson<String?>(json['slug']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      primaryMuscle: serializer.fromJson<String?>(json['primaryMuscle']),
      secondaryMuscles: serializer.fromJson<String?>(json['secondaryMuscles']),
      equipment: serializer.fromJson<String?>(json['equipment']),
      description: serializer.fromJson<String?>(json['description']),
      tracksWeight: serializer.fromJson<bool>(json['tracksWeight']),
      tracksReps: serializer.fromJson<bool>(json['tracksReps']),
      tracksDuration: serializer.fromJson<bool>(json['tracksDuration']),
      tracksDistance: serializer.fromJson<bool>(json['tracksDistance']),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'slug': serializer.toJson<String?>(slug),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'primaryMuscle': serializer.toJson<String?>(primaryMuscle),
      'secondaryMuscles': serializer.toJson<String?>(secondaryMuscles),
      'equipment': serializer.toJson<String?>(equipment),
      'description': serializer.toJson<String?>(description),
      'tracksWeight': serializer.toJson<bool>(tracksWeight),
      'tracksReps': serializer.toJson<bool>(tracksReps),
      'tracksDuration': serializer.toJson<bool>(tracksDuration),
      'tracksDistance': serializer.toJson<bool>(tracksDistance),
      'isCustom': serializer.toJson<bool>(isCustom),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Exercise copyWith({
    int? id,
    Value<String?> slug = const Value.absent(),
    String? name,
    String? category,
    Value<String?> primaryMuscle = const Value.absent(),
    Value<String?> secondaryMuscles = const Value.absent(),
    Value<String?> equipment = const Value.absent(),
    Value<String?> description = const Value.absent(),
    bool? tracksWeight,
    bool? tracksReps,
    bool? tracksDuration,
    bool? tracksDistance,
    bool? isCustom,
    DateTime? createdAt,
  }) => Exercise(
    id: id ?? this.id,
    slug: slug.present ? slug.value : this.slug,
    name: name ?? this.name,
    category: category ?? this.category,
    primaryMuscle: primaryMuscle.present
        ? primaryMuscle.value
        : this.primaryMuscle,
    secondaryMuscles: secondaryMuscles.present
        ? secondaryMuscles.value
        : this.secondaryMuscles,
    equipment: equipment.present ? equipment.value : this.equipment,
    description: description.present ? description.value : this.description,
    tracksWeight: tracksWeight ?? this.tracksWeight,
    tracksReps: tracksReps ?? this.tracksReps,
    tracksDuration: tracksDuration ?? this.tracksDuration,
    tracksDistance: tracksDistance ?? this.tracksDistance,
    isCustom: isCustom ?? this.isCustom,
    createdAt: createdAt ?? this.createdAt,
  );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      id: data.id.present ? data.id.value : this.id,
      slug: data.slug.present ? data.slug.value : this.slug,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      primaryMuscle: data.primaryMuscle.present
          ? data.primaryMuscle.value
          : this.primaryMuscle,
      secondaryMuscles: data.secondaryMuscles.present
          ? data.secondaryMuscles.value
          : this.secondaryMuscles,
      equipment: data.equipment.present ? data.equipment.value : this.equipment,
      description: data.description.present
          ? data.description.value
          : this.description,
      tracksWeight: data.tracksWeight.present
          ? data.tracksWeight.value
          : this.tracksWeight,
      tracksReps: data.tracksReps.present
          ? data.tracksReps.value
          : this.tracksReps,
      tracksDuration: data.tracksDuration.present
          ? data.tracksDuration.value
          : this.tracksDuration,
      tracksDistance: data.tracksDistance.present
          ? data.tracksDistance.value
          : this.tracksDistance,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('id: $id, ')
          ..write('slug: $slug, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('primaryMuscle: $primaryMuscle, ')
          ..write('secondaryMuscles: $secondaryMuscles, ')
          ..write('equipment: $equipment, ')
          ..write('description: $description, ')
          ..write('tracksWeight: $tracksWeight, ')
          ..write('tracksReps: $tracksReps, ')
          ..write('tracksDuration: $tracksDuration, ')
          ..write('tracksDistance: $tracksDistance, ')
          ..write('isCustom: $isCustom, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    slug,
    name,
    category,
    primaryMuscle,
    secondaryMuscles,
    equipment,
    description,
    tracksWeight,
    tracksReps,
    tracksDuration,
    tracksDistance,
    isCustom,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.id == this.id &&
          other.slug == this.slug &&
          other.name == this.name &&
          other.category == this.category &&
          other.primaryMuscle == this.primaryMuscle &&
          other.secondaryMuscles == this.secondaryMuscles &&
          other.equipment == this.equipment &&
          other.description == this.description &&
          other.tracksWeight == this.tracksWeight &&
          other.tracksReps == this.tracksReps &&
          other.tracksDuration == this.tracksDuration &&
          other.tracksDistance == this.tracksDistance &&
          other.isCustom == this.isCustom &&
          other.createdAt == this.createdAt);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<int> id;
  final Value<String?> slug;
  final Value<String> name;
  final Value<String> category;
  final Value<String?> primaryMuscle;
  final Value<String?> secondaryMuscles;
  final Value<String?> equipment;
  final Value<String?> description;
  final Value<bool> tracksWeight;
  final Value<bool> tracksReps;
  final Value<bool> tracksDuration;
  final Value<bool> tracksDistance;
  final Value<bool> isCustom;
  final Value<DateTime> createdAt;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.slug = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.primaryMuscle = const Value.absent(),
    this.secondaryMuscles = const Value.absent(),
    this.equipment = const Value.absent(),
    this.description = const Value.absent(),
    this.tracksWeight = const Value.absent(),
    this.tracksReps = const Value.absent(),
    this.tracksDuration = const Value.absent(),
    this.tracksDistance = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ExercisesCompanion.insert({
    this.id = const Value.absent(),
    this.slug = const Value.absent(),
    required String name,
    required String category,
    this.primaryMuscle = const Value.absent(),
    this.secondaryMuscles = const Value.absent(),
    this.equipment = const Value.absent(),
    this.description = const Value.absent(),
    this.tracksWeight = const Value.absent(),
    this.tracksReps = const Value.absent(),
    this.tracksDuration = const Value.absent(),
    this.tracksDistance = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       category = Value(category);
  static Insertable<Exercise> custom({
    Expression<int>? id,
    Expression<String>? slug,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? primaryMuscle,
    Expression<String>? secondaryMuscles,
    Expression<String>? equipment,
    Expression<String>? description,
    Expression<bool>? tracksWeight,
    Expression<bool>? tracksReps,
    Expression<bool>? tracksDuration,
    Expression<bool>? tracksDistance,
    Expression<bool>? isCustom,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (slug != null) 'slug': slug,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (primaryMuscle != null) 'primary_muscle': primaryMuscle,
      if (secondaryMuscles != null) 'secondary_muscles': secondaryMuscles,
      if (equipment != null) 'equipment': equipment,
      if (description != null) 'description': description,
      if (tracksWeight != null) 'tracks_weight': tracksWeight,
      if (tracksReps != null) 'tracks_reps': tracksReps,
      if (tracksDuration != null) 'tracks_duration': tracksDuration,
      if (tracksDistance != null) 'tracks_distance': tracksDistance,
      if (isCustom != null) 'is_custom': isCustom,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ExercisesCompanion copyWith({
    Value<int>? id,
    Value<String?>? slug,
    Value<String>? name,
    Value<String>? category,
    Value<String?>? primaryMuscle,
    Value<String?>? secondaryMuscles,
    Value<String?>? equipment,
    Value<String?>? description,
    Value<bool>? tracksWeight,
    Value<bool>? tracksReps,
    Value<bool>? tracksDuration,
    Value<bool>? tracksDistance,
    Value<bool>? isCustom,
    Value<DateTime>? createdAt,
  }) {
    return ExercisesCompanion(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      category: category ?? this.category,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      equipment: equipment ?? this.equipment,
      description: description ?? this.description,
      tracksWeight: tracksWeight ?? this.tracksWeight,
      tracksReps: tracksReps ?? this.tracksReps,
      tracksDuration: tracksDuration ?? this.tracksDuration,
      tracksDistance: tracksDistance ?? this.tracksDistance,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (primaryMuscle.present) {
      map['primary_muscle'] = Variable<String>(primaryMuscle.value);
    }
    if (secondaryMuscles.present) {
      map['secondary_muscles'] = Variable<String>(secondaryMuscles.value);
    }
    if (equipment.present) {
      map['equipment'] = Variable<String>(equipment.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (tracksWeight.present) {
      map['tracks_weight'] = Variable<bool>(tracksWeight.value);
    }
    if (tracksReps.present) {
      map['tracks_reps'] = Variable<bool>(tracksReps.value);
    }
    if (tracksDuration.present) {
      map['tracks_duration'] = Variable<bool>(tracksDuration.value);
    }
    if (tracksDistance.present) {
      map['tracks_distance'] = Variable<bool>(tracksDistance.value);
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('id: $id, ')
          ..write('slug: $slug, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('primaryMuscle: $primaryMuscle, ')
          ..write('secondaryMuscles: $secondaryMuscles, ')
          ..write('equipment: $equipment, ')
          ..write('description: $description, ')
          ..write('tracksWeight: $tracksWeight, ')
          ..write('tracksReps: $tracksReps, ')
          ..write('tracksDuration: $tracksDuration, ')
          ..write('tracksDistance: $tracksDistance, ')
          ..write('isCustom: $isCustom, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WorkoutSessionsTable extends WorkoutSessions
    with TableInfo<$WorkoutSessionsTable, WorkoutSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayIdMeta = const VerificationMeta('dayId');
  @override
  late final GeneratedColumn<int> dayId = GeneratedColumn<int>(
    'day_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecMeta = const VerificationMeta(
    'durationSec',
  );
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
    'duration_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _perceivedEffortMeta = const VerificationMeta(
    'perceivedEffort',
  );
  @override
  late final GeneratedColumn<int> perceivedEffort = GeneratedColumn<int>(
    'perceived_effort',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    dayId,
    name,
    startedAt,
    completedAt,
    durationSec,
    perceivedEffort,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('day_id')) {
      context.handle(
        _dayIdMeta,
        dayId.isAcceptableOrUnknown(data['day_id']!, _dayIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
        _durationSecMeta,
        durationSec.isAcceptableOrUnknown(
          data['duration_sec']!,
          _durationSecMeta,
        ),
      );
    }
    if (data.containsKey('perceived_effort')) {
      context.handle(
        _perceivedEffortMeta,
        perceivedEffort.isAcceptableOrUnknown(
          data['perceived_effort']!,
          _perceivedEffortMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      dayId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      durationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_sec'],
      ),
      perceivedEffort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}perceived_effort'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $WorkoutSessionsTable createAlias(String alias) {
    return $WorkoutSessionsTable(attachedDatabase, alias);
  }
}

class WorkoutSession extends DataClass implements Insertable<WorkoutSession> {
  final int id;
  final String date;
  final int? dayId;
  final String name;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? durationSec;
  final int? perceivedEffort;
  final String? notes;
  const WorkoutSession({
    required this.id,
    required this.date,
    this.dayId,
    required this.name,
    this.startedAt,
    this.completedAt,
    this.durationSec,
    this.perceivedEffort,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || dayId != null) {
      map['day_id'] = Variable<int>(dayId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || durationSec != null) {
      map['duration_sec'] = Variable<int>(durationSec);
    }
    if (!nullToAbsent || perceivedEffort != null) {
      map['perceived_effort'] = Variable<int>(perceivedEffort);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  WorkoutSessionsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSessionsCompanion(
      id: Value(id),
      date: Value(date),
      dayId: dayId == null && nullToAbsent
          ? const Value.absent()
          : Value(dayId),
      name: Value(name),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      durationSec: durationSec == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSec),
      perceivedEffort: perceivedEffort == null && nullToAbsent
          ? const Value.absent()
          : Value(perceivedEffort),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory WorkoutSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSession(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      dayId: serializer.fromJson<int?>(json['dayId']),
      name: serializer.fromJson<String>(json['name']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      durationSec: serializer.fromJson<int?>(json['durationSec']),
      perceivedEffort: serializer.fromJson<int?>(json['perceivedEffort']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(date),
      'dayId': serializer.toJson<int?>(dayId),
      'name': serializer.toJson<String>(name),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'durationSec': serializer.toJson<int?>(durationSec),
      'perceivedEffort': serializer.toJson<int?>(perceivedEffort),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  WorkoutSession copyWith({
    int? id,
    String? date,
    Value<int?> dayId = const Value.absent(),
    String? name,
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
    Value<int?> durationSec = const Value.absent(),
    Value<int?> perceivedEffort = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => WorkoutSession(
    id: id ?? this.id,
    date: date ?? this.date,
    dayId: dayId.present ? dayId.value : this.dayId,
    name: name ?? this.name,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    durationSec: durationSec.present ? durationSec.value : this.durationSec,
    perceivedEffort: perceivedEffort.present
        ? perceivedEffort.value
        : this.perceivedEffort,
    notes: notes.present ? notes.value : this.notes,
  );
  WorkoutSession copyWithCompanion(WorkoutSessionsCompanion data) {
    return WorkoutSession(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      dayId: data.dayId.present ? data.dayId.value : this.dayId,
      name: data.name.present ? data.name.value : this.name,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      durationSec: data.durationSec.present
          ? data.durationSec.value
          : this.durationSec,
      perceivedEffort: data.perceivedEffort.present
          ? data.perceivedEffort.value
          : this.perceivedEffort,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSession(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('dayId: $dayId, ')
          ..write('name: $name, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('durationSec: $durationSec, ')
          ..write('perceivedEffort: $perceivedEffort, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    dayId,
    name,
    startedAt,
    completedAt,
    durationSec,
    perceivedEffort,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSession &&
          other.id == this.id &&
          other.date == this.date &&
          other.dayId == this.dayId &&
          other.name == this.name &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.durationSec == this.durationSec &&
          other.perceivedEffort == this.perceivedEffort &&
          other.notes == this.notes);
}

class WorkoutSessionsCompanion extends UpdateCompanion<WorkoutSession> {
  final Value<int> id;
  final Value<String> date;
  final Value<int?> dayId;
  final Value<String> name;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> completedAt;
  final Value<int?> durationSec;
  final Value<int?> perceivedEffort;
  final Value<String?> notes;
  const WorkoutSessionsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.dayId = const Value.absent(),
    this.name = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.perceivedEffort = const Value.absent(),
    this.notes = const Value.absent(),
  });
  WorkoutSessionsCompanion.insert({
    this.id = const Value.absent(),
    required String date,
    this.dayId = const Value.absent(),
    required String name,
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.perceivedEffort = const Value.absent(),
    this.notes = const Value.absent(),
  }) : date = Value(date),
       name = Value(name);
  static Insertable<WorkoutSession> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<int>? dayId,
    Expression<String>? name,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<int>? durationSec,
    Expression<int>? perceivedEffort,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (dayId != null) 'day_id': dayId,
      if (name != null) 'name': name,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (durationSec != null) 'duration_sec': durationSec,
      if (perceivedEffort != null) 'perceived_effort': perceivedEffort,
      if (notes != null) 'notes': notes,
    });
  }

  WorkoutSessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? date,
    Value<int?>? dayId,
    Value<String>? name,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? completedAt,
    Value<int?>? durationSec,
    Value<int?>? perceivedEffort,
    Value<String?>? notes,
  }) {
    return WorkoutSessionsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      dayId: dayId ?? this.dayId,
      name: name ?? this.name,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      durationSec: durationSec ?? this.durationSec,
      perceivedEffort: perceivedEffort ?? this.perceivedEffort,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (dayId.present) {
      map['day_id'] = Variable<int>(dayId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
    }
    if (perceivedEffort.present) {
      map['perceived_effort'] = Variable<int>(perceivedEffort.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSessionsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('dayId: $dayId, ')
          ..write('name: $name, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('durationSec: $durationSec, ')
          ..write('perceivedEffort: $perceivedEffort, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $SetEntriesTable extends SetEntries
    with TableInfo<$SetEntriesTable, SetEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SetEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workout_sessions (id)',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id)',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setIndexMeta = const VerificationMeta(
    'setIndex',
  );
  @override
  late final GeneratedColumn<int> setIndex = GeneratedColumn<int>(
    'set_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecMeta = const VerificationMeta(
    'durationSec',
  );
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
    'duration_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceMMeta = const VerificationMeta(
    'distanceM',
  );
  @override
  late final GeneratedColumn<double> distanceM = GeneratedColumn<double>(
    'distance_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rpeMeta = const VerificationMeta('rpe');
  @override
  late final GeneratedColumn<double> rpe = GeneratedColumn<double>(
    'rpe',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enteredUnitMeta = const VerificationMeta(
    'enteredUnit',
  );
  @override
  late final GeneratedColumn<String> enteredUnit = GeneratedColumn<String>(
    'entered_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isWarmupMeta = const VerificationMeta(
    'isWarmup',
  );
  @override
  late final GeneratedColumn<bool> isWarmup = GeneratedColumn<bool>(
    'is_warmup',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_warmup" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    exerciseId,
    position,
    setIndex,
    reps,
    weightKg,
    durationSec,
    distanceM,
    rpe,
    enteredUnit,
    isWarmup,
    completed,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'set_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SetEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('set_index')) {
      context.handle(
        _setIndexMeta,
        setIndex.isAcceptableOrUnknown(data['set_index']!, _setIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_setIndexMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
        _durationSecMeta,
        durationSec.isAcceptableOrUnknown(
          data['duration_sec']!,
          _durationSecMeta,
        ),
      );
    }
    if (data.containsKey('distance_m')) {
      context.handle(
        _distanceMMeta,
        distanceM.isAcceptableOrUnknown(data['distance_m']!, _distanceMMeta),
      );
    }
    if (data.containsKey('rpe')) {
      context.handle(
        _rpeMeta,
        rpe.isAcceptableOrUnknown(data['rpe']!, _rpeMeta),
      );
    }
    if (data.containsKey('entered_unit')) {
      context.handle(
        _enteredUnitMeta,
        enteredUnit.isAcceptableOrUnknown(
          data['entered_unit']!,
          _enteredUnitMeta,
        ),
      );
    }
    if (data.containsKey('is_warmup')) {
      context.handle(
        _isWarmupMeta,
        isWarmup.isAcceptableOrUnknown(data['is_warmup']!, _isWarmupMeta),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SetEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SetEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      setIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}set_index'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      ),
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      durationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_sec'],
      ),
      distanceM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_m'],
      ),
      rpe: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rpe'],
      ),
      enteredUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entered_unit'],
      ),
      isWarmup: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_warmup'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SetEntriesTable createAlias(String alias) {
    return $SetEntriesTable(attachedDatabase, alias);
  }
}

class SetEntry extends DataClass implements Insertable<SetEntry> {
  final int id;
  final int sessionId;
  final int exerciseId;
  final int position;
  final int setIndex;
  final int? reps;
  final double? weightKg;
  final int? durationSec;
  final double? distanceM;
  final double? rpe;
  final String? enteredUnit;
  final bool isWarmup;
  final bool completed;
  final DateTime createdAt;
  const SetEntry({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.position,
    required this.setIndex,
    this.reps,
    this.weightKg,
    this.durationSec,
    this.distanceM,
    this.rpe,
    this.enteredUnit,
    required this.isWarmup,
    required this.completed,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['exercise_id'] = Variable<int>(exerciseId);
    map['position'] = Variable<int>(position);
    map['set_index'] = Variable<int>(setIndex);
    if (!nullToAbsent || reps != null) {
      map['reps'] = Variable<int>(reps);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || durationSec != null) {
      map['duration_sec'] = Variable<int>(durationSec);
    }
    if (!nullToAbsent || distanceM != null) {
      map['distance_m'] = Variable<double>(distanceM);
    }
    if (!nullToAbsent || rpe != null) {
      map['rpe'] = Variable<double>(rpe);
    }
    if (!nullToAbsent || enteredUnit != null) {
      map['entered_unit'] = Variable<String>(enteredUnit);
    }
    map['is_warmup'] = Variable<bool>(isWarmup);
    map['completed'] = Variable<bool>(completed);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SetEntriesCompanion toCompanion(bool nullToAbsent) {
    return SetEntriesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      exerciseId: Value(exerciseId),
      position: Value(position),
      setIndex: Value(setIndex),
      reps: reps == null && nullToAbsent ? const Value.absent() : Value(reps),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      durationSec: durationSec == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSec),
      distanceM: distanceM == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceM),
      rpe: rpe == null && nullToAbsent ? const Value.absent() : Value(rpe),
      enteredUnit: enteredUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(enteredUnit),
      isWarmup: Value(isWarmup),
      completed: Value(completed),
      createdAt: Value(createdAt),
    );
  }

  factory SetEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SetEntry(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      exerciseId: serializer.fromJson<int>(json['exerciseId']),
      position: serializer.fromJson<int>(json['position']),
      setIndex: serializer.fromJson<int>(json['setIndex']),
      reps: serializer.fromJson<int?>(json['reps']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      durationSec: serializer.fromJson<int?>(json['durationSec']),
      distanceM: serializer.fromJson<double?>(json['distanceM']),
      rpe: serializer.fromJson<double?>(json['rpe']),
      enteredUnit: serializer.fromJson<String?>(json['enteredUnit']),
      isWarmup: serializer.fromJson<bool>(json['isWarmup']),
      completed: serializer.fromJson<bool>(json['completed']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'exerciseId': serializer.toJson<int>(exerciseId),
      'position': serializer.toJson<int>(position),
      'setIndex': serializer.toJson<int>(setIndex),
      'reps': serializer.toJson<int?>(reps),
      'weightKg': serializer.toJson<double?>(weightKg),
      'durationSec': serializer.toJson<int?>(durationSec),
      'distanceM': serializer.toJson<double?>(distanceM),
      'rpe': serializer.toJson<double?>(rpe),
      'enteredUnit': serializer.toJson<String?>(enteredUnit),
      'isWarmup': serializer.toJson<bool>(isWarmup),
      'completed': serializer.toJson<bool>(completed),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SetEntry copyWith({
    int? id,
    int? sessionId,
    int? exerciseId,
    int? position,
    int? setIndex,
    Value<int?> reps = const Value.absent(),
    Value<double?> weightKg = const Value.absent(),
    Value<int?> durationSec = const Value.absent(),
    Value<double?> distanceM = const Value.absent(),
    Value<double?> rpe = const Value.absent(),
    Value<String?> enteredUnit = const Value.absent(),
    bool? isWarmup,
    bool? completed,
    DateTime? createdAt,
  }) => SetEntry(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    exerciseId: exerciseId ?? this.exerciseId,
    position: position ?? this.position,
    setIndex: setIndex ?? this.setIndex,
    reps: reps.present ? reps.value : this.reps,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    durationSec: durationSec.present ? durationSec.value : this.durationSec,
    distanceM: distanceM.present ? distanceM.value : this.distanceM,
    rpe: rpe.present ? rpe.value : this.rpe,
    enteredUnit: enteredUnit.present ? enteredUnit.value : this.enteredUnit,
    isWarmup: isWarmup ?? this.isWarmup,
    completed: completed ?? this.completed,
    createdAt: createdAt ?? this.createdAt,
  );
  SetEntry copyWithCompanion(SetEntriesCompanion data) {
    return SetEntry(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      position: data.position.present ? data.position.value : this.position,
      setIndex: data.setIndex.present ? data.setIndex.value : this.setIndex,
      reps: data.reps.present ? data.reps.value : this.reps,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      durationSec: data.durationSec.present
          ? data.durationSec.value
          : this.durationSec,
      distanceM: data.distanceM.present ? data.distanceM.value : this.distanceM,
      rpe: data.rpe.present ? data.rpe.value : this.rpe,
      enteredUnit: data.enteredUnit.present
          ? data.enteredUnit.value
          : this.enteredUnit,
      isWarmup: data.isWarmup.present ? data.isWarmup.value : this.isWarmup,
      completed: data.completed.present ? data.completed.value : this.completed,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SetEntry(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('setIndex: $setIndex, ')
          ..write('reps: $reps, ')
          ..write('weightKg: $weightKg, ')
          ..write('durationSec: $durationSec, ')
          ..write('distanceM: $distanceM, ')
          ..write('rpe: $rpe, ')
          ..write('enteredUnit: $enteredUnit, ')
          ..write('isWarmup: $isWarmup, ')
          ..write('completed: $completed, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    exerciseId,
    position,
    setIndex,
    reps,
    weightKg,
    durationSec,
    distanceM,
    rpe,
    enteredUnit,
    isWarmup,
    completed,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetEntry &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.exerciseId == this.exerciseId &&
          other.position == this.position &&
          other.setIndex == this.setIndex &&
          other.reps == this.reps &&
          other.weightKg == this.weightKg &&
          other.durationSec == this.durationSec &&
          other.distanceM == this.distanceM &&
          other.rpe == this.rpe &&
          other.enteredUnit == this.enteredUnit &&
          other.isWarmup == this.isWarmup &&
          other.completed == this.completed &&
          other.createdAt == this.createdAt);
}

class SetEntriesCompanion extends UpdateCompanion<SetEntry> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<int> exerciseId;
  final Value<int> position;
  final Value<int> setIndex;
  final Value<int?> reps;
  final Value<double?> weightKg;
  final Value<int?> durationSec;
  final Value<double?> distanceM;
  final Value<double?> rpe;
  final Value<String?> enteredUnit;
  final Value<bool> isWarmup;
  final Value<bool> completed;
  final Value<DateTime> createdAt;
  const SetEntriesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.position = const Value.absent(),
    this.setIndex = const Value.absent(),
    this.reps = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.rpe = const Value.absent(),
    this.enteredUnit = const Value.absent(),
    this.isWarmup = const Value.absent(),
    this.completed = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SetEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required int exerciseId,
    required int position,
    required int setIndex,
    this.reps = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.rpe = const Value.absent(),
    this.enteredUnit = const Value.absent(),
    this.isWarmup = const Value.absent(),
    this.completed = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : sessionId = Value(sessionId),
       exerciseId = Value(exerciseId),
       position = Value(position),
       setIndex = Value(setIndex);
  static Insertable<SetEntry> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<int>? exerciseId,
    Expression<int>? position,
    Expression<int>? setIndex,
    Expression<int>? reps,
    Expression<double>? weightKg,
    Expression<int>? durationSec,
    Expression<double>? distanceM,
    Expression<double>? rpe,
    Expression<String>? enteredUnit,
    Expression<bool>? isWarmup,
    Expression<bool>? completed,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (position != null) 'position': position,
      if (setIndex != null) 'set_index': setIndex,
      if (reps != null) 'reps': reps,
      if (weightKg != null) 'weight_kg': weightKg,
      if (durationSec != null) 'duration_sec': durationSec,
      if (distanceM != null) 'distance_m': distanceM,
      if (rpe != null) 'rpe': rpe,
      if (enteredUnit != null) 'entered_unit': enteredUnit,
      if (isWarmup != null) 'is_warmup': isWarmup,
      if (completed != null) 'completed': completed,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SetEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<int>? exerciseId,
    Value<int>? position,
    Value<int>? setIndex,
    Value<int?>? reps,
    Value<double?>? weightKg,
    Value<int?>? durationSec,
    Value<double?>? distanceM,
    Value<double?>? rpe,
    Value<String?>? enteredUnit,
    Value<bool>? isWarmup,
    Value<bool>? completed,
    Value<DateTime>? createdAt,
  }) {
    return SetEntriesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      position: position ?? this.position,
      setIndex: setIndex ?? this.setIndex,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      durationSec: durationSec ?? this.durationSec,
      distanceM: distanceM ?? this.distanceM,
      rpe: rpe ?? this.rpe,
      enteredUnit: enteredUnit ?? this.enteredUnit,
      isWarmup: isWarmup ?? this.isWarmup,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (setIndex.present) {
      map['set_index'] = Variable<int>(setIndex.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
    }
    if (distanceM.present) {
      map['distance_m'] = Variable<double>(distanceM.value);
    }
    if (rpe.present) {
      map['rpe'] = Variable<double>(rpe.value);
    }
    if (enteredUnit.present) {
      map['entered_unit'] = Variable<String>(enteredUnit.value);
    }
    if (isWarmup.present) {
      map['is_warmup'] = Variable<bool>(isWarmup.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SetEntriesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('setIndex: $setIndex, ')
          ..write('reps: $reps, ')
          ..write('weightKg: $weightKg, ')
          ..write('durationSec: $durationSec, ')
          ..write('distanceM: $distanceM, ')
          ..write('rpe: $rpe, ')
          ..write('enteredUnit: $enteredUnit, ')
          ..write('isWarmup: $isWarmup, ')
          ..write('completed: $completed, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WorkoutTemplatesTable extends WorkoutTemplates
    with TableInfo<$WorkoutTemplatesTable, WorkoutTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, notes, position, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WorkoutTemplatesTable createAlias(String alias) {
    return $WorkoutTemplatesTable(attachedDatabase, alias);
  }
}

class WorkoutTemplate extends DataClass implements Insertable<WorkoutTemplate> {
  final int id;
  final String name;
  final String? notes;
  final int position;
  final DateTime createdAt;
  const WorkoutTemplate({
    required this.id,
    required this.name,
    this.notes,
    required this.position,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['position'] = Variable<int>(position);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WorkoutTemplatesCompanion toCompanion(bool nullToAbsent) {
    return WorkoutTemplatesCompanion(
      id: Value(id),
      name: Value(name),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      position: Value(position),
      createdAt: Value(createdAt),
    );
  }

  factory WorkoutTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutTemplate(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      notes: serializer.fromJson<String?>(json['notes']),
      position: serializer.fromJson<int>(json['position']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'notes': serializer.toJson<String?>(notes),
      'position': serializer.toJson<int>(position),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  WorkoutTemplate copyWith({
    int? id,
    String? name,
    Value<String?> notes = const Value.absent(),
    int? position,
    DateTime? createdAt,
  }) => WorkoutTemplate(
    id: id ?? this.id,
    name: name ?? this.name,
    notes: notes.present ? notes.value : this.notes,
    position: position ?? this.position,
    createdAt: createdAt ?? this.createdAt,
  );
  WorkoutTemplate copyWithCompanion(WorkoutTemplatesCompanion data) {
    return WorkoutTemplate(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      notes: data.notes.present ? data.notes.value : this.notes,
      position: data.position.present ? data.position.value : this.position,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutTemplate(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, notes, position, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutTemplate &&
          other.id == this.id &&
          other.name == this.name &&
          other.notes == this.notes &&
          other.position == this.position &&
          other.createdAt == this.createdAt);
}

class WorkoutTemplatesCompanion extends UpdateCompanion<WorkoutTemplate> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> notes;
  final Value<int> position;
  final Value<DateTime> createdAt;
  const WorkoutTemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  WorkoutTemplatesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.notes = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<WorkoutTemplate> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? notes,
    Expression<int>? position,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (notes != null) 'notes': notes,
      if (position != null) 'position': position,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  WorkoutTemplatesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? notes,
    Value<int>? position,
    Value<DateTime>? createdAt,
  }) {
    return WorkoutTemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TemplateDaysTable extends TemplateDays
    with TableInfo<$TemplateDaysTable, TemplateDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplateDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<int> templateId = GeneratedColumn<int>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workout_templates (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    templateId,
    name,
    position,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'template_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<TemplateDay> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TemplateDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateDay(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TemplateDaysTable createAlias(String alias) {
    return $TemplateDaysTable(attachedDatabase, alias);
  }
}

class TemplateDay extends DataClass implements Insertable<TemplateDay> {
  final int id;
  final int templateId;
  final String name;
  final int position;
  final String? notes;
  final DateTime createdAt;
  const TemplateDay({
    required this.id,
    required this.templateId,
    required this.name,
    required this.position,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['template_id'] = Variable<int>(templateId);
    map['name'] = Variable<String>(name);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TemplateDaysCompanion toCompanion(bool nullToAbsent) {
    return TemplateDaysCompanion(
      id: Value(id),
      templateId: Value(templateId),
      name: Value(name),
      position: Value(position),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory TemplateDay.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateDay(
      id: serializer.fromJson<int>(json['id']),
      templateId: serializer.fromJson<int>(json['templateId']),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<int>(json['position']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'templateId': serializer.toJson<int>(templateId),
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<int>(position),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TemplateDay copyWith({
    int? id,
    int? templateId,
    String? name,
    int? position,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
  }) => TemplateDay(
    id: id ?? this.id,
    templateId: templateId ?? this.templateId,
    name: name ?? this.name,
    position: position ?? this.position,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  TemplateDay copyWithCompanion(TemplateDaysCompanion data) {
    return TemplateDay(
      id: data.id.present ? data.id.value : this.id,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateDay(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, templateId, name, position, notes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateDay &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.name == this.name &&
          other.position == this.position &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class TemplateDaysCompanion extends UpdateCompanion<TemplateDay> {
  final Value<int> id;
  final Value<int> templateId;
  final Value<String> name;
  final Value<int> position;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  const TemplateDaysCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TemplateDaysCompanion.insert({
    this.id = const Value.absent(),
    required int templateId,
    required String name,
    this.position = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : templateId = Value(templateId),
       name = Value(name);
  static Insertable<TemplateDay> custom({
    Expression<int>? id,
    Expression<int>? templateId,
    Expression<String>? name,
    Expression<int>? position,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TemplateDaysCompanion copyWith({
    Value<int>? id,
    Value<int>? templateId,
    Value<String>? name,
    Value<int>? position,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
  }) {
    return TemplateDaysCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      position: position ?? this.position,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<int>(templateId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplateDaysCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TemplateExercisesTable extends TemplateExercises
    with TableInfo<$TemplateExercisesTable, TemplateExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplateExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dayIdMeta = const VerificationMeta('dayId');
  @override
  late final GeneratedColumn<int> dayId = GeneratedColumn<int>(
    'day_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES template_days (id)',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id)',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetSetsMeta = const VerificationMeta(
    'targetSets',
  );
  @override
  late final GeneratedColumn<int> targetSets = GeneratedColumn<int>(
    'target_sets',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetRepsMeta = const VerificationMeta(
    'targetReps',
  );
  @override
  late final GeneratedColumn<String> targetReps = GeneratedColumn<String>(
    'target_reps',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetWeightKgMeta = const VerificationMeta(
    'targetWeightKg',
  );
  @override
  late final GeneratedColumn<double> targetWeightKg = GeneratedColumn<double>(
    'target_weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetDurationSecMeta = const VerificationMeta(
    'targetDurationSec',
  );
  @override
  late final GeneratedColumn<int> targetDurationSec = GeneratedColumn<int>(
    'target_duration_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetDistanceMMeta = const VerificationMeta(
    'targetDistanceM',
  );
  @override
  late final GeneratedColumn<double> targetDistanceM = GeneratedColumn<double>(
    'target_distance_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dayId,
    exerciseId,
    position,
    targetSets,
    targetReps,
    targetWeightKg,
    targetDurationSec,
    targetDistanceM,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'template_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<TemplateExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day_id')) {
      context.handle(
        _dayIdMeta,
        dayId.isAcceptableOrUnknown(data['day_id']!, _dayIdMeta),
      );
    } else if (isInserting) {
      context.missing(_dayIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('target_sets')) {
      context.handle(
        _targetSetsMeta,
        targetSets.isAcceptableOrUnknown(data['target_sets']!, _targetSetsMeta),
      );
    }
    if (data.containsKey('target_reps')) {
      context.handle(
        _targetRepsMeta,
        targetReps.isAcceptableOrUnknown(data['target_reps']!, _targetRepsMeta),
      );
    }
    if (data.containsKey('target_weight_kg')) {
      context.handle(
        _targetWeightKgMeta,
        targetWeightKg.isAcceptableOrUnknown(
          data['target_weight_kg']!,
          _targetWeightKgMeta,
        ),
      );
    }
    if (data.containsKey('target_duration_sec')) {
      context.handle(
        _targetDurationSecMeta,
        targetDurationSec.isAcceptableOrUnknown(
          data['target_duration_sec']!,
          _targetDurationSecMeta,
        ),
      );
    }
    if (data.containsKey('target_distance_m')) {
      context.handle(
        _targetDistanceMMeta,
        targetDistanceM.isAcceptableOrUnknown(
          data['target_distance_m']!,
          _targetDistanceMMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TemplateExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateExercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dayId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      targetSets: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_sets'],
      ),
      targetReps: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_reps'],
      ),
      targetWeightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_weight_kg'],
      ),
      targetDurationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_duration_sec'],
      ),
      targetDistanceM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_distance_m'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $TemplateExercisesTable createAlias(String alias) {
    return $TemplateExercisesTable(attachedDatabase, alias);
  }
}

class TemplateExercise extends DataClass
    implements Insertable<TemplateExercise> {
  final int id;
  final int dayId;
  final int exerciseId;
  final int position;
  final int? targetSets;
  final String? targetReps;
  final double? targetWeightKg;
  final int? targetDurationSec;
  final double? targetDistanceM;
  final String? notes;
  const TemplateExercise({
    required this.id,
    required this.dayId,
    required this.exerciseId,
    required this.position,
    this.targetSets,
    this.targetReps,
    this.targetWeightKg,
    this.targetDurationSec,
    this.targetDistanceM,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day_id'] = Variable<int>(dayId);
    map['exercise_id'] = Variable<int>(exerciseId);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || targetSets != null) {
      map['target_sets'] = Variable<int>(targetSets);
    }
    if (!nullToAbsent || targetReps != null) {
      map['target_reps'] = Variable<String>(targetReps);
    }
    if (!nullToAbsent || targetWeightKg != null) {
      map['target_weight_kg'] = Variable<double>(targetWeightKg);
    }
    if (!nullToAbsent || targetDurationSec != null) {
      map['target_duration_sec'] = Variable<int>(targetDurationSec);
    }
    if (!nullToAbsent || targetDistanceM != null) {
      map['target_distance_m'] = Variable<double>(targetDistanceM);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  TemplateExercisesCompanion toCompanion(bool nullToAbsent) {
    return TemplateExercisesCompanion(
      id: Value(id),
      dayId: Value(dayId),
      exerciseId: Value(exerciseId),
      position: Value(position),
      targetSets: targetSets == null && nullToAbsent
          ? const Value.absent()
          : Value(targetSets),
      targetReps: targetReps == null && nullToAbsent
          ? const Value.absent()
          : Value(targetReps),
      targetWeightKg: targetWeightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(targetWeightKg),
      targetDurationSec: targetDurationSec == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDurationSec),
      targetDistanceM: targetDistanceM == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDistanceM),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory TemplateExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateExercise(
      id: serializer.fromJson<int>(json['id']),
      dayId: serializer.fromJson<int>(json['dayId']),
      exerciseId: serializer.fromJson<int>(json['exerciseId']),
      position: serializer.fromJson<int>(json['position']),
      targetSets: serializer.fromJson<int?>(json['targetSets']),
      targetReps: serializer.fromJson<String?>(json['targetReps']),
      targetWeightKg: serializer.fromJson<double?>(json['targetWeightKg']),
      targetDurationSec: serializer.fromJson<int?>(json['targetDurationSec']),
      targetDistanceM: serializer.fromJson<double?>(json['targetDistanceM']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dayId': serializer.toJson<int>(dayId),
      'exerciseId': serializer.toJson<int>(exerciseId),
      'position': serializer.toJson<int>(position),
      'targetSets': serializer.toJson<int?>(targetSets),
      'targetReps': serializer.toJson<String?>(targetReps),
      'targetWeightKg': serializer.toJson<double?>(targetWeightKg),
      'targetDurationSec': serializer.toJson<int?>(targetDurationSec),
      'targetDistanceM': serializer.toJson<double?>(targetDistanceM),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  TemplateExercise copyWith({
    int? id,
    int? dayId,
    int? exerciseId,
    int? position,
    Value<int?> targetSets = const Value.absent(),
    Value<String?> targetReps = const Value.absent(),
    Value<double?> targetWeightKg = const Value.absent(),
    Value<int?> targetDurationSec = const Value.absent(),
    Value<double?> targetDistanceM = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => TemplateExercise(
    id: id ?? this.id,
    dayId: dayId ?? this.dayId,
    exerciseId: exerciseId ?? this.exerciseId,
    position: position ?? this.position,
    targetSets: targetSets.present ? targetSets.value : this.targetSets,
    targetReps: targetReps.present ? targetReps.value : this.targetReps,
    targetWeightKg: targetWeightKg.present
        ? targetWeightKg.value
        : this.targetWeightKg,
    targetDurationSec: targetDurationSec.present
        ? targetDurationSec.value
        : this.targetDurationSec,
    targetDistanceM: targetDistanceM.present
        ? targetDistanceM.value
        : this.targetDistanceM,
    notes: notes.present ? notes.value : this.notes,
  );
  TemplateExercise copyWithCompanion(TemplateExercisesCompanion data) {
    return TemplateExercise(
      id: data.id.present ? data.id.value : this.id,
      dayId: data.dayId.present ? data.dayId.value : this.dayId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      position: data.position.present ? data.position.value : this.position,
      targetSets: data.targetSets.present
          ? data.targetSets.value
          : this.targetSets,
      targetReps: data.targetReps.present
          ? data.targetReps.value
          : this.targetReps,
      targetWeightKg: data.targetWeightKg.present
          ? data.targetWeightKg.value
          : this.targetWeightKg,
      targetDurationSec: data.targetDurationSec.present
          ? data.targetDurationSec.value
          : this.targetDurationSec,
      targetDistanceM: data.targetDistanceM.present
          ? data.targetDistanceM.value
          : this.targetDistanceM,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateExercise(')
          ..write('id: $id, ')
          ..write('dayId: $dayId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('targetSets: $targetSets, ')
          ..write('targetReps: $targetReps, ')
          ..write('targetWeightKg: $targetWeightKg, ')
          ..write('targetDurationSec: $targetDurationSec, ')
          ..write('targetDistanceM: $targetDistanceM, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dayId,
    exerciseId,
    position,
    targetSets,
    targetReps,
    targetWeightKg,
    targetDurationSec,
    targetDistanceM,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateExercise &&
          other.id == this.id &&
          other.dayId == this.dayId &&
          other.exerciseId == this.exerciseId &&
          other.position == this.position &&
          other.targetSets == this.targetSets &&
          other.targetReps == this.targetReps &&
          other.targetWeightKg == this.targetWeightKg &&
          other.targetDurationSec == this.targetDurationSec &&
          other.targetDistanceM == this.targetDistanceM &&
          other.notes == this.notes);
}

class TemplateExercisesCompanion extends UpdateCompanion<TemplateExercise> {
  final Value<int> id;
  final Value<int> dayId;
  final Value<int> exerciseId;
  final Value<int> position;
  final Value<int?> targetSets;
  final Value<String?> targetReps;
  final Value<double?> targetWeightKg;
  final Value<int?> targetDurationSec;
  final Value<double?> targetDistanceM;
  final Value<String?> notes;
  const TemplateExercisesCompanion({
    this.id = const Value.absent(),
    this.dayId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.position = const Value.absent(),
    this.targetSets = const Value.absent(),
    this.targetReps = const Value.absent(),
    this.targetWeightKg = const Value.absent(),
    this.targetDurationSec = const Value.absent(),
    this.targetDistanceM = const Value.absent(),
    this.notes = const Value.absent(),
  });
  TemplateExercisesCompanion.insert({
    this.id = const Value.absent(),
    required int dayId,
    required int exerciseId,
    required int position,
    this.targetSets = const Value.absent(),
    this.targetReps = const Value.absent(),
    this.targetWeightKg = const Value.absent(),
    this.targetDurationSec = const Value.absent(),
    this.targetDistanceM = const Value.absent(),
    this.notes = const Value.absent(),
  }) : dayId = Value(dayId),
       exerciseId = Value(exerciseId),
       position = Value(position);
  static Insertable<TemplateExercise> custom({
    Expression<int>? id,
    Expression<int>? dayId,
    Expression<int>? exerciseId,
    Expression<int>? position,
    Expression<int>? targetSets,
    Expression<String>? targetReps,
    Expression<double>? targetWeightKg,
    Expression<int>? targetDurationSec,
    Expression<double>? targetDistanceM,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dayId != null) 'day_id': dayId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (position != null) 'position': position,
      if (targetSets != null) 'target_sets': targetSets,
      if (targetReps != null) 'target_reps': targetReps,
      if (targetWeightKg != null) 'target_weight_kg': targetWeightKg,
      if (targetDurationSec != null) 'target_duration_sec': targetDurationSec,
      if (targetDistanceM != null) 'target_distance_m': targetDistanceM,
      if (notes != null) 'notes': notes,
    });
  }

  TemplateExercisesCompanion copyWith({
    Value<int>? id,
    Value<int>? dayId,
    Value<int>? exerciseId,
    Value<int>? position,
    Value<int?>? targetSets,
    Value<String?>? targetReps,
    Value<double?>? targetWeightKg,
    Value<int?>? targetDurationSec,
    Value<double?>? targetDistanceM,
    Value<String?>? notes,
  }) {
    return TemplateExercisesCompanion(
      id: id ?? this.id,
      dayId: dayId ?? this.dayId,
      exerciseId: exerciseId ?? this.exerciseId,
      position: position ?? this.position,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      targetDurationSec: targetDurationSec ?? this.targetDurationSec,
      targetDistanceM: targetDistanceM ?? this.targetDistanceM,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dayId.present) {
      map['day_id'] = Variable<int>(dayId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (targetSets.present) {
      map['target_sets'] = Variable<int>(targetSets.value);
    }
    if (targetReps.present) {
      map['target_reps'] = Variable<String>(targetReps.value);
    }
    if (targetWeightKg.present) {
      map['target_weight_kg'] = Variable<double>(targetWeightKg.value);
    }
    if (targetDurationSec.present) {
      map['target_duration_sec'] = Variable<int>(targetDurationSec.value);
    }
    if (targetDistanceM.present) {
      map['target_distance_m'] = Variable<double>(targetDistanceM.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplateExercisesCompanion(')
          ..write('id: $id, ')
          ..write('dayId: $dayId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('targetSets: $targetSets, ')
          ..write('targetReps: $targetReps, ')
          ..write('targetWeightKg: $targetWeightKg, ')
          ..write('targetDurationSec: $targetDurationSec, ')
          ..write('targetDistanceM: $targetDistanceM, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $ScheduleEntriesTable extends ScheduleEntries
    with TableInfo<$ScheduleEntriesTable, ScheduleEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduleEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dayOfWeekMeta = const VerificationMeta(
    'dayOfWeek',
  );
  @override
  late final GeneratedColumn<int> dayOfWeek = GeneratedColumn<int>(
    'day_of_week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayIdMeta = const VerificationMeta('dayId');
  @override
  late final GeneratedColumn<int> dayId = GeneratedColumn<int>(
    'day_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES template_days (id)',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, dayOfWeek, dayId, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedule_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScheduleEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day_of_week')) {
      context.handle(
        _dayOfWeekMeta,
        dayOfWeek.isAcceptableOrUnknown(data['day_of_week']!, _dayOfWeekMeta),
      );
    } else if (isInserting) {
      context.missing(_dayOfWeekMeta);
    }
    if (data.containsKey('day_id')) {
      context.handle(
        _dayIdMeta,
        dayId.isAcceptableOrUnknown(data['day_id']!, _dayIdMeta),
      );
    } else if (isInserting) {
      context.missing(_dayIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScheduleEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduleEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dayOfWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_week'],
      )!,
      dayId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $ScheduleEntriesTable createAlias(String alias) {
    return $ScheduleEntriesTable(attachedDatabase, alias);
  }
}

class ScheduleEntry extends DataClass implements Insertable<ScheduleEntry> {
  final int id;
  final int dayOfWeek;
  final int dayId;
  final int position;
  const ScheduleEntry({
    required this.id,
    required this.dayOfWeek,
    required this.dayId,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day_of_week'] = Variable<int>(dayOfWeek);
    map['day_id'] = Variable<int>(dayId);
    map['position'] = Variable<int>(position);
    return map;
  }

  ScheduleEntriesCompanion toCompanion(bool nullToAbsent) {
    return ScheduleEntriesCompanion(
      id: Value(id),
      dayOfWeek: Value(dayOfWeek),
      dayId: Value(dayId),
      position: Value(position),
    );
  }

  factory ScheduleEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduleEntry(
      id: serializer.fromJson<int>(json['id']),
      dayOfWeek: serializer.fromJson<int>(json['dayOfWeek']),
      dayId: serializer.fromJson<int>(json['dayId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dayOfWeek': serializer.toJson<int>(dayOfWeek),
      'dayId': serializer.toJson<int>(dayId),
      'position': serializer.toJson<int>(position),
    };
  }

  ScheduleEntry copyWith({
    int? id,
    int? dayOfWeek,
    int? dayId,
    int? position,
  }) => ScheduleEntry(
    id: id ?? this.id,
    dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    dayId: dayId ?? this.dayId,
    position: position ?? this.position,
  );
  ScheduleEntry copyWithCompanion(ScheduleEntriesCompanion data) {
    return ScheduleEntry(
      id: data.id.present ? data.id.value : this.id,
      dayOfWeek: data.dayOfWeek.present ? data.dayOfWeek.value : this.dayOfWeek,
      dayId: data.dayId.present ? data.dayId.value : this.dayId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleEntry(')
          ..write('id: $id, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('dayId: $dayId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dayOfWeek, dayId, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduleEntry &&
          other.id == this.id &&
          other.dayOfWeek == this.dayOfWeek &&
          other.dayId == this.dayId &&
          other.position == this.position);
}

class ScheduleEntriesCompanion extends UpdateCompanion<ScheduleEntry> {
  final Value<int> id;
  final Value<int> dayOfWeek;
  final Value<int> dayId;
  final Value<int> position;
  const ScheduleEntriesCompanion({
    this.id = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.dayId = const Value.absent(),
    this.position = const Value.absent(),
  });
  ScheduleEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int dayOfWeek,
    required int dayId,
    this.position = const Value.absent(),
  }) : dayOfWeek = Value(dayOfWeek),
       dayId = Value(dayId);
  static Insertable<ScheduleEntry> custom({
    Expression<int>? id,
    Expression<int>? dayOfWeek,
    Expression<int>? dayId,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (dayId != null) 'day_id': dayId,
      if (position != null) 'position': position,
    });
  }

  ScheduleEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? dayOfWeek,
    Value<int>? dayId,
    Value<int>? position,
  }) {
    return ScheduleEntriesCompanion(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      dayId: dayId ?? this.dayId,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dayOfWeek.present) {
      map['day_of_week'] = Variable<int>(dayOfWeek.value);
    }
    if (dayId.present) {
      map['day_id'] = Variable<int>(dayId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleEntriesCompanion(')
          ..write('id: $id, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('dayId: $dayId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

class $DailyActivityTable extends DailyActivity
    with TableInfo<$DailyActivityTable, DailyActivityData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyActivityTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepsMeta = const VerificationMeta('steps');
  @override
  late final GeneratedColumn<int> steps = GeneratedColumn<int>(
    'steps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMinutesMeta = const VerificationMeta(
    'activeMinutes',
  );
  @override
  late final GeneratedColumn<int> activeMinutes = GeneratedColumn<int>(
    'active_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  @override
  List<GeneratedColumn> get $columns => [date, steps, activeMinutes, source];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_activity';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyActivityData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('steps')) {
      context.handle(
        _stepsMeta,
        steps.isAcceptableOrUnknown(data['steps']!, _stepsMeta),
      );
    }
    if (data.containsKey('active_minutes')) {
      context.handle(
        _activeMinutesMeta,
        activeMinutes.isAcceptableOrUnknown(
          data['active_minutes']!,
          _activeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  DailyActivityData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyActivityData(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      steps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}steps'],
      ),
      activeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}active_minutes'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $DailyActivityTable createAlias(String alias) {
    return $DailyActivityTable(attachedDatabase, alias);
  }
}

class DailyActivityData extends DataClass
    implements Insertable<DailyActivityData> {
  final String date;
  final int? steps;
  final int? activeMinutes;
  final String source;
  const DailyActivityData({
    required this.date,
    this.steps,
    this.activeMinutes,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || steps != null) {
      map['steps'] = Variable<int>(steps);
    }
    if (!nullToAbsent || activeMinutes != null) {
      map['active_minutes'] = Variable<int>(activeMinutes);
    }
    map['source'] = Variable<String>(source);
    return map;
  }

  DailyActivityCompanion toCompanion(bool nullToAbsent) {
    return DailyActivityCompanion(
      date: Value(date),
      steps: steps == null && nullToAbsent
          ? const Value.absent()
          : Value(steps),
      activeMinutes: activeMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(activeMinutes),
      source: Value(source),
    );
  }

  factory DailyActivityData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyActivityData(
      date: serializer.fromJson<String>(json['date']),
      steps: serializer.fromJson<int?>(json['steps']),
      activeMinutes: serializer.fromJson<int?>(json['activeMinutes']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'steps': serializer.toJson<int?>(steps),
      'activeMinutes': serializer.toJson<int?>(activeMinutes),
      'source': serializer.toJson<String>(source),
    };
  }

  DailyActivityData copyWith({
    String? date,
    Value<int?> steps = const Value.absent(),
    Value<int?> activeMinutes = const Value.absent(),
    String? source,
  }) => DailyActivityData(
    date: date ?? this.date,
    steps: steps.present ? steps.value : this.steps,
    activeMinutes: activeMinutes.present
        ? activeMinutes.value
        : this.activeMinutes,
    source: source ?? this.source,
  );
  DailyActivityData copyWithCompanion(DailyActivityCompanion data) {
    return DailyActivityData(
      date: data.date.present ? data.date.value : this.date,
      steps: data.steps.present ? data.steps.value : this.steps,
      activeMinutes: data.activeMinutes.present
          ? data.activeMinutes.value
          : this.activeMinutes,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyActivityData(')
          ..write('date: $date, ')
          ..write('steps: $steps, ')
          ..write('activeMinutes: $activeMinutes, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, steps, activeMinutes, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyActivityData &&
          other.date == this.date &&
          other.steps == this.steps &&
          other.activeMinutes == this.activeMinutes &&
          other.source == this.source);
}

class DailyActivityCompanion extends UpdateCompanion<DailyActivityData> {
  final Value<String> date;
  final Value<int?> steps;
  final Value<int?> activeMinutes;
  final Value<String> source;
  final Value<int> rowid;
  const DailyActivityCompanion({
    this.date = const Value.absent(),
    this.steps = const Value.absent(),
    this.activeMinutes = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyActivityCompanion.insert({
    required String date,
    this.steps = const Value.absent(),
    this.activeMinutes = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date);
  static Insertable<DailyActivityData> custom({
    Expression<String>? date,
    Expression<int>? steps,
    Expression<int>? activeMinutes,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (steps != null) 'steps': steps,
      if (activeMinutes != null) 'active_minutes': activeMinutes,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyActivityCompanion copyWith({
    Value<String>? date,
    Value<int?>? steps,
    Value<int?>? activeMinutes,
    Value<String>? source,
    Value<int>? rowid,
  }) {
    return DailyActivityCompanion(
      date: date ?? this.date,
      steps: steps ?? this.steps,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (steps.present) {
      map['steps'] = Variable<int>(steps.value);
    }
    if (activeMinutes.present) {
      map['active_minutes'] = Variable<int>(activeMinutes.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyActivityCompanion(')
          ..write('date: $date, ')
          ..write('steps: $steps, ')
          ..write('activeMinutes: $activeMinutes, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RecipesTable recipes = $RecipesTable(this);
  late final $RecipeIngredientsTable recipeIngredients =
      $RecipeIngredientsTable(this);
  late final $RecipeStepsTable recipeSteps = $RecipeStepsTable(this);
  late final $RecipeNutritionCacheTable recipeNutritionCache =
      $RecipeNutritionCacheTable(this);
  late final $FoodCacheTable foodCache = $FoodCacheTable(this);
  late final $FoodUnitWeightsTable foodUnitWeights = $FoodUnitWeightsTable(
    this,
  );
  late final $LogEntriesTable logEntries = $LogEntriesTable(this);
  late final $DailyTargetsTableTable dailyTargetsTable =
      $DailyTargetsTableTable(this);
  late final $AdaptiveTargetsTable adaptiveTargets = $AdaptiveTargetsTable(
    this,
  );
  late final $SettingsTable settings = $SettingsTable(this);
  late final $GroceryItemsTable groceryItems = $GroceryItemsTable(this);
  late final $WeightEntriesTable weightEntries = $WeightEntriesTable(this);
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $WorkoutSessionsTable workoutSessions = $WorkoutSessionsTable(
    this,
  );
  late final $SetEntriesTable setEntries = $SetEntriesTable(this);
  late final $WorkoutTemplatesTable workoutTemplates = $WorkoutTemplatesTable(
    this,
  );
  late final $TemplateDaysTable templateDays = $TemplateDaysTable(this);
  late final $TemplateExercisesTable templateExercises =
      $TemplateExercisesTable(this);
  late final $ScheduleEntriesTable scheduleEntries = $ScheduleEntriesTable(
    this,
  );
  late final $DailyActivityTable dailyActivity = $DailyActivityTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    recipes,
    recipeIngredients,
    recipeSteps,
    recipeNutritionCache,
    foodCache,
    foodUnitWeights,
    logEntries,
    dailyTargetsTable,
    adaptiveTargets,
    settings,
    groceryItems,
    weightEntries,
    exercises,
    workoutSessions,
    setEntries,
    workoutTemplates,
    templateDays,
    templateExercises,
    scheduleEntries,
    dailyActivity,
  ];
}

typedef $$RecipesTableCreateCompanionBuilder =
    RecipesCompanion Function({
      Value<int> id,
      required String title,
      Value<DateTime> createdAt,
      Value<int> servings,
    });
typedef $$RecipesTableUpdateCompanionBuilder =
    RecipesCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<DateTime> createdAt,
      Value<int> servings,
    });

final class $$RecipesTableReferences
    extends BaseReferences<_$AppDatabase, $RecipesTable, Recipe> {
  $$RecipesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RecipeIngredientsTable, List<RecipeIngredient>>
  _recipeIngredientsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.recipeIngredients,
        aliasName: $_aliasNameGenerator(
          db.recipes.id,
          db.recipeIngredients.recipeId,
        ),
      );

  $$RecipeIngredientsTableProcessedTableManager get recipeIngredientsRefs {
    final manager = $$RecipeIngredientsTableTableManager(
      $_db,
      $_db.recipeIngredients,
    ).filter((f) => f.recipeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _recipeIngredientsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RecipeStepsTable, List<RecipeStep>>
  _recipeStepsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.recipeSteps,
    aliasName: $_aliasNameGenerator(db.recipes.id, db.recipeSteps.recipeId),
  );

  $$RecipeStepsTableProcessedTableManager get recipeStepsRefs {
    final manager = $$RecipeStepsTableTableManager(
      $_db,
      $_db.recipeSteps,
    ).filter((f) => f.recipeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_recipeStepsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $RecipeNutritionCacheTable,
    List<RecipeNutritionCacheData>
  >
  _recipeNutritionCacheRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.recipeNutritionCache,
        aliasName: $_aliasNameGenerator(
          db.recipes.id,
          db.recipeNutritionCache.recipeId,
        ),
      );

  $$RecipeNutritionCacheTableProcessedTableManager
  get recipeNutritionCacheRefs {
    final manager = $$RecipeNutritionCacheTableTableManager(
      $_db,
      $_db.recipeNutritionCache,
    ).filter((f) => f.recipeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _recipeNutritionCacheRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RecipesTableFilterComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get servings => $composableBuilder(
    column: $table.servings,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> recipeIngredientsRefs(
    Expression<bool> Function($$RecipeIngredientsTableFilterComposer f) f,
  ) {
    final $$RecipeIngredientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recipeIngredients,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipeIngredientsTableFilterComposer(
            $db: $db,
            $table: $db.recipeIngredients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> recipeStepsRefs(
    Expression<bool> Function($$RecipeStepsTableFilterComposer f) f,
  ) {
    final $$RecipeStepsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recipeSteps,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipeStepsTableFilterComposer(
            $db: $db,
            $table: $db.recipeSteps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> recipeNutritionCacheRefs(
    Expression<bool> Function($$RecipeNutritionCacheTableFilterComposer f) f,
  ) {
    final $$RecipeNutritionCacheTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recipeNutritionCache,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipeNutritionCacheTableFilterComposer(
            $db: $db,
            $table: $db.recipeNutritionCache,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecipesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get servings => $composableBuilder(
    column: $table.servings,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecipesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get servings =>
      $composableBuilder(column: $table.servings, builder: (column) => column);

  Expression<T> recipeIngredientsRefs<T extends Object>(
    Expression<T> Function($$RecipeIngredientsTableAnnotationComposer a) f,
  ) {
    final $$RecipeIngredientsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.recipeIngredients,
          getReferencedColumn: (t) => t.recipeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RecipeIngredientsTableAnnotationComposer(
                $db: $db,
                $table: $db.recipeIngredients,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> recipeStepsRefs<T extends Object>(
    Expression<T> Function($$RecipeStepsTableAnnotationComposer a) f,
  ) {
    final $$RecipeStepsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recipeSteps,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipeStepsTableAnnotationComposer(
            $db: $db,
            $table: $db.recipeSteps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> recipeNutritionCacheRefs<T extends Object>(
    Expression<T> Function($$RecipeNutritionCacheTableAnnotationComposer a) f,
  ) {
    final $$RecipeNutritionCacheTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.recipeNutritionCache,
          getReferencedColumn: (t) => t.recipeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RecipeNutritionCacheTableAnnotationComposer(
                $db: $db,
                $table: $db.recipeNutritionCache,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$RecipesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipesTable,
          Recipe,
          $$RecipesTableFilterComposer,
          $$RecipesTableOrderingComposer,
          $$RecipesTableAnnotationComposer,
          $$RecipesTableCreateCompanionBuilder,
          $$RecipesTableUpdateCompanionBuilder,
          (Recipe, $$RecipesTableReferences),
          Recipe,
          PrefetchHooks Function({
            bool recipeIngredientsRefs,
            bool recipeStepsRefs,
            bool recipeNutritionCacheRefs,
          })
        > {
  $$RecipesTableTableManager(_$AppDatabase db, $RecipesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> servings = const Value.absent(),
              }) => RecipesCompanion(
                id: id,
                title: title,
                createdAt: createdAt,
                servings: servings,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> servings = const Value.absent(),
              }) => RecipesCompanion.insert(
                id: id,
                title: title,
                createdAt: createdAt,
                servings: servings,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RecipesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                recipeIngredientsRefs = false,
                recipeStepsRefs = false,
                recipeNutritionCacheRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (recipeIngredientsRefs) db.recipeIngredients,
                    if (recipeStepsRefs) db.recipeSteps,
                    if (recipeNutritionCacheRefs) db.recipeNutritionCache,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (recipeIngredientsRefs)
                        await $_getPrefetchedData<
                          Recipe,
                          $RecipesTable,
                          RecipeIngredient
                        >(
                          currentTable: table,
                          referencedTable: $$RecipesTableReferences
                              ._recipeIngredientsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecipesTableReferences(
                                db,
                                table,
                                p0,
                              ).recipeIngredientsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recipeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (recipeStepsRefs)
                        await $_getPrefetchedData<
                          Recipe,
                          $RecipesTable,
                          RecipeStep
                        >(
                          currentTable: table,
                          referencedTable: $$RecipesTableReferences
                              ._recipeStepsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecipesTableReferences(
                                db,
                                table,
                                p0,
                              ).recipeStepsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recipeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (recipeNutritionCacheRefs)
                        await $_getPrefetchedData<
                          Recipe,
                          $RecipesTable,
                          RecipeNutritionCacheData
                        >(
                          currentTable: table,
                          referencedTable: $$RecipesTableReferences
                              ._recipeNutritionCacheRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecipesTableReferences(
                                db,
                                table,
                                p0,
                              ).recipeNutritionCacheRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recipeId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RecipesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipesTable,
      Recipe,
      $$RecipesTableFilterComposer,
      $$RecipesTableOrderingComposer,
      $$RecipesTableAnnotationComposer,
      $$RecipesTableCreateCompanionBuilder,
      $$RecipesTableUpdateCompanionBuilder,
      (Recipe, $$RecipesTableReferences),
      Recipe,
      PrefetchHooks Function({
        bool recipeIngredientsRefs,
        bool recipeStepsRefs,
        bool recipeNutritionCacheRefs,
      })
    >;
typedef $$RecipeIngredientsTableCreateCompanionBuilder =
    RecipeIngredientsCompanion Function({
      Value<int> id,
      required int recipeId,
      required String name,
      Value<String?> quantity,
      Value<String?> unit,
    });
typedef $$RecipeIngredientsTableUpdateCompanionBuilder =
    RecipeIngredientsCompanion Function({
      Value<int> id,
      Value<int> recipeId,
      Value<String> name,
      Value<String?> quantity,
      Value<String?> unit,
    });

final class $$RecipeIngredientsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RecipeIngredientsTable,
          RecipeIngredient
        > {
  $$RecipeIngredientsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias(
        $_aliasNameGenerator(db.recipeIngredients.recipeId, db.recipes.id),
      );

  $$RecipesTableProcessedTableManager get recipeId {
    final $_column = $_itemColumn<int>('recipe_id')!;

    final manager = $$RecipesTableTableManager(
      $_db,
      $_db.recipes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RecipeIngredientsTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeIngredientsTable> {
  $$RecipeIngredientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableFilterComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeIngredientsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeIngredientsTable> {
  $$RecipeIngredientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableOrderingComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeIngredientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeIngredientsTable> {
  $$RecipeIngredientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableAnnotationComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeIngredientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipeIngredientsTable,
          RecipeIngredient,
          $$RecipeIngredientsTableFilterComposer,
          $$RecipeIngredientsTableOrderingComposer,
          $$RecipeIngredientsTableAnnotationComposer,
          $$RecipeIngredientsTableCreateCompanionBuilder,
          $$RecipeIngredientsTableUpdateCompanionBuilder,
          (RecipeIngredient, $$RecipeIngredientsTableReferences),
          RecipeIngredient,
          PrefetchHooks Function({bool recipeId})
        > {
  $$RecipeIngredientsTableTableManager(
    _$AppDatabase db,
    $RecipeIngredientsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeIngredientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeIngredientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeIngredientsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> recipeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
              }) => RecipeIngredientsCompanion(
                id: id,
                recipeId: recipeId,
                name: name,
                quantity: quantity,
                unit: unit,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int recipeId,
                required String name,
                Value<String?> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
              }) => RecipeIngredientsCompanion.insert(
                id: id,
                recipeId: recipeId,
                name: name,
                quantity: quantity,
                unit: unit,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RecipeIngredientsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recipeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recipeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recipeId,
                                referencedTable:
                                    $$RecipeIngredientsTableReferences
                                        ._recipeIdTable(db),
                                referencedColumn:
                                    $$RecipeIngredientsTableReferences
                                        ._recipeIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RecipeIngredientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipeIngredientsTable,
      RecipeIngredient,
      $$RecipeIngredientsTableFilterComposer,
      $$RecipeIngredientsTableOrderingComposer,
      $$RecipeIngredientsTableAnnotationComposer,
      $$RecipeIngredientsTableCreateCompanionBuilder,
      $$RecipeIngredientsTableUpdateCompanionBuilder,
      (RecipeIngredient, $$RecipeIngredientsTableReferences),
      RecipeIngredient,
      PrefetchHooks Function({bool recipeId})
    >;
typedef $$RecipeStepsTableCreateCompanionBuilder =
    RecipeStepsCompanion Function({
      Value<int> id,
      required int recipeId,
      required int position,
      required String stepText,
    });
typedef $$RecipeStepsTableUpdateCompanionBuilder =
    RecipeStepsCompanion Function({
      Value<int> id,
      Value<int> recipeId,
      Value<int> position,
      Value<String> stepText,
    });

final class $$RecipeStepsTableReferences
    extends BaseReferences<_$AppDatabase, $RecipeStepsTable, RecipeStep> {
  $$RecipeStepsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias(
        $_aliasNameGenerator(db.recipeSteps.recipeId, db.recipes.id),
      );

  $$RecipesTableProcessedTableManager get recipeId {
    final $_column = $_itemColumn<int>('recipe_id')!;

    final manager = $$RecipesTableTableManager(
      $_db,
      $_db.recipes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RecipeStepsTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeStepsTable> {
  $$RecipeStepsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stepText => $composableBuilder(
    column: $table.stepText,
    builder: (column) => ColumnFilters(column),
  );

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableFilterComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeStepsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeStepsTable> {
  $$RecipeStepsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stepText => $composableBuilder(
    column: $table.stepText,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableOrderingComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeStepsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeStepsTable> {
  $$RecipeStepsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get stepText =>
      $composableBuilder(column: $table.stepText, builder: (column) => column);

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableAnnotationComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeStepsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipeStepsTable,
          RecipeStep,
          $$RecipeStepsTableFilterComposer,
          $$RecipeStepsTableOrderingComposer,
          $$RecipeStepsTableAnnotationComposer,
          $$RecipeStepsTableCreateCompanionBuilder,
          $$RecipeStepsTableUpdateCompanionBuilder,
          (RecipeStep, $$RecipeStepsTableReferences),
          RecipeStep,
          PrefetchHooks Function({bool recipeId})
        > {
  $$RecipeStepsTableTableManager(_$AppDatabase db, $RecipeStepsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeStepsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeStepsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeStepsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> recipeId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> stepText = const Value.absent(),
              }) => RecipeStepsCompanion(
                id: id,
                recipeId: recipeId,
                position: position,
                stepText: stepText,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int recipeId,
                required int position,
                required String stepText,
              }) => RecipeStepsCompanion.insert(
                id: id,
                recipeId: recipeId,
                position: position,
                stepText: stepText,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RecipeStepsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recipeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recipeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recipeId,
                                referencedTable: $$RecipeStepsTableReferences
                                    ._recipeIdTable(db),
                                referencedColumn: $$RecipeStepsTableReferences
                                    ._recipeIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RecipeStepsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipeStepsTable,
      RecipeStep,
      $$RecipeStepsTableFilterComposer,
      $$RecipeStepsTableOrderingComposer,
      $$RecipeStepsTableAnnotationComposer,
      $$RecipeStepsTableCreateCompanionBuilder,
      $$RecipeStepsTableUpdateCompanionBuilder,
      (RecipeStep, $$RecipeStepsTableReferences),
      RecipeStep,
      PrefetchHooks Function({bool recipeId})
    >;
typedef $$RecipeNutritionCacheTableCreateCompanionBuilder =
    RecipeNutritionCacheCompanion Function({
      Value<int> recipeId,
      required String ingredientsHash,
      required String breakdownJson,
      Value<DateTime> updatedAt,
    });
typedef $$RecipeNutritionCacheTableUpdateCompanionBuilder =
    RecipeNutritionCacheCompanion Function({
      Value<int> recipeId,
      Value<String> ingredientsHash,
      Value<String> breakdownJson,
      Value<DateTime> updatedAt,
    });

final class $$RecipeNutritionCacheTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RecipeNutritionCacheTable,
          RecipeNutritionCacheData
        > {
  $$RecipeNutritionCacheTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias(
        $_aliasNameGenerator(db.recipeNutritionCache.recipeId, db.recipes.id),
      );

  $$RecipesTableProcessedTableManager get recipeId {
    final $_column = $_itemColumn<int>('recipe_id')!;

    final manager = $$RecipesTableTableManager(
      $_db,
      $_db.recipes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RecipeNutritionCacheTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeNutritionCacheTable> {
  $$RecipeNutritionCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ingredientsHash => $composableBuilder(
    column: $table.ingredientsHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get breakdownJson => $composableBuilder(
    column: $table.breakdownJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableFilterComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeNutritionCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeNutritionCacheTable> {
  $$RecipeNutritionCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ingredientsHash => $composableBuilder(
    column: $table.ingredientsHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get breakdownJson => $composableBuilder(
    column: $table.breakdownJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableOrderingComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeNutritionCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeNutritionCacheTable> {
  $$RecipeNutritionCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ingredientsHash => $composableBuilder(
    column: $table.ingredientsHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get breakdownJson => $composableBuilder(
    column: $table.breakdownJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableAnnotationComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeNutritionCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipeNutritionCacheTable,
          RecipeNutritionCacheData,
          $$RecipeNutritionCacheTableFilterComposer,
          $$RecipeNutritionCacheTableOrderingComposer,
          $$RecipeNutritionCacheTableAnnotationComposer,
          $$RecipeNutritionCacheTableCreateCompanionBuilder,
          $$RecipeNutritionCacheTableUpdateCompanionBuilder,
          (RecipeNutritionCacheData, $$RecipeNutritionCacheTableReferences),
          RecipeNutritionCacheData,
          PrefetchHooks Function({bool recipeId})
        > {
  $$RecipeNutritionCacheTableTableManager(
    _$AppDatabase db,
    $RecipeNutritionCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeNutritionCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeNutritionCacheTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RecipeNutritionCacheTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> recipeId = const Value.absent(),
                Value<String> ingredientsHash = const Value.absent(),
                Value<String> breakdownJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => RecipeNutritionCacheCompanion(
                recipeId: recipeId,
                ingredientsHash: ingredientsHash,
                breakdownJson: breakdownJson,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> recipeId = const Value.absent(),
                required String ingredientsHash,
                required String breakdownJson,
                Value<DateTime> updatedAt = const Value.absent(),
              }) => RecipeNutritionCacheCompanion.insert(
                recipeId: recipeId,
                ingredientsHash: ingredientsHash,
                breakdownJson: breakdownJson,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RecipeNutritionCacheTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recipeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recipeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recipeId,
                                referencedTable:
                                    $$RecipeNutritionCacheTableReferences
                                        ._recipeIdTable(db),
                                referencedColumn:
                                    $$RecipeNutritionCacheTableReferences
                                        ._recipeIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RecipeNutritionCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipeNutritionCacheTable,
      RecipeNutritionCacheData,
      $$RecipeNutritionCacheTableFilterComposer,
      $$RecipeNutritionCacheTableOrderingComposer,
      $$RecipeNutritionCacheTableAnnotationComposer,
      $$RecipeNutritionCacheTableCreateCompanionBuilder,
      $$RecipeNutritionCacheTableUpdateCompanionBuilder,
      (RecipeNutritionCacheData, $$RecipeNutritionCacheTableReferences),
      RecipeNutritionCacheData,
      PrefetchHooks Function({bool recipeId})
    >;
typedef $$FoodCacheTableCreateCompanionBuilder =
    FoodCacheCompanion Function({
      Value<int> id,
      required String name,
      required String source,
      required double kcal100,
      required double protein100,
      required double carb100,
      required double fat100,
      Value<bool> isEstimate,
      Value<bool> userOverride,
      Value<double?> gramsPerPiece,
      Value<double?> fibre100,
      Value<double?> sodium100,
      Value<double?> basisQuantity,
      Value<String?> basisUnit,
      Value<double?> basisKcal,
      Value<double?> basisProtein,
      Value<double?> basisCarb,
      Value<double?> basisFat,
      Value<double?> basisPhysicalGrams,
      Value<bool> basisNeedsReview,
      Value<String?> sourceUrl,
      Value<String?> sourceTitle,
      Value<DateTime?> sourceRetrievedAt,
      Value<String?> sourceInferredFields,
    });
typedef $$FoodCacheTableUpdateCompanionBuilder =
    FoodCacheCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> source,
      Value<double> kcal100,
      Value<double> protein100,
      Value<double> carb100,
      Value<double> fat100,
      Value<bool> isEstimate,
      Value<bool> userOverride,
      Value<double?> gramsPerPiece,
      Value<double?> fibre100,
      Value<double?> sodium100,
      Value<double?> basisQuantity,
      Value<String?> basisUnit,
      Value<double?> basisKcal,
      Value<double?> basisProtein,
      Value<double?> basisCarb,
      Value<double?> basisFat,
      Value<double?> basisPhysicalGrams,
      Value<bool> basisNeedsReview,
      Value<String?> sourceUrl,
      Value<String?> sourceTitle,
      Value<DateTime?> sourceRetrievedAt,
      Value<String?> sourceInferredFields,
    });

class $$FoodCacheTableFilterComposer
    extends Composer<_$AppDatabase, $FoodCacheTable> {
  $$FoodCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kcal100 => $composableBuilder(
    column: $table.kcal100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get protein100 => $composableBuilder(
    column: $table.protein100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carb100 => $composableBuilder(
    column: $table.carb100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fat100 => $composableBuilder(
    column: $table.fat100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEstimate => $composableBuilder(
    column: $table.isEstimate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get userOverride => $composableBuilder(
    column: $table.userOverride,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gramsPerPiece => $composableBuilder(
    column: $table.gramsPerPiece,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fibre100 => $composableBuilder(
    column: $table.fibre100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sodium100 => $composableBuilder(
    column: $table.sodium100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get basisQuantity => $composableBuilder(
    column: $table.basisQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get basisUnit => $composableBuilder(
    column: $table.basisUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get basisKcal => $composableBuilder(
    column: $table.basisKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get basisProtein => $composableBuilder(
    column: $table.basisProtein,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get basisCarb => $composableBuilder(
    column: $table.basisCarb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get basisFat => $composableBuilder(
    column: $table.basisFat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get basisPhysicalGrams => $composableBuilder(
    column: $table.basisPhysicalGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get basisNeedsReview => $composableBuilder(
    column: $table.basisNeedsReview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceTitle => $composableBuilder(
    column: $table.sourceTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sourceRetrievedAt => $composableBuilder(
    column: $table.sourceRetrievedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceInferredFields => $composableBuilder(
    column: $table.sourceInferredFields,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoodCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodCacheTable> {
  $$FoodCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcal100 => $composableBuilder(
    column: $table.kcal100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get protein100 => $composableBuilder(
    column: $table.protein100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carb100 => $composableBuilder(
    column: $table.carb100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fat100 => $composableBuilder(
    column: $table.fat100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEstimate => $composableBuilder(
    column: $table.isEstimate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get userOverride => $composableBuilder(
    column: $table.userOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gramsPerPiece => $composableBuilder(
    column: $table.gramsPerPiece,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fibre100 => $composableBuilder(
    column: $table.fibre100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sodium100 => $composableBuilder(
    column: $table.sodium100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get basisQuantity => $composableBuilder(
    column: $table.basisQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get basisUnit => $composableBuilder(
    column: $table.basisUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get basisKcal => $composableBuilder(
    column: $table.basisKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get basisProtein => $composableBuilder(
    column: $table.basisProtein,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get basisCarb => $composableBuilder(
    column: $table.basisCarb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get basisFat => $composableBuilder(
    column: $table.basisFat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get basisPhysicalGrams => $composableBuilder(
    column: $table.basisPhysicalGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get basisNeedsReview => $composableBuilder(
    column: $table.basisNeedsReview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceTitle => $composableBuilder(
    column: $table.sourceTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sourceRetrievedAt => $composableBuilder(
    column: $table.sourceRetrievedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceInferredFields => $composableBuilder(
    column: $table.sourceInferredFields,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodCacheTable> {
  $$FoodCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<double> get kcal100 =>
      $composableBuilder(column: $table.kcal100, builder: (column) => column);

  GeneratedColumn<double> get protein100 => $composableBuilder(
    column: $table.protein100,
    builder: (column) => column,
  );

  GeneratedColumn<double> get carb100 =>
      $composableBuilder(column: $table.carb100, builder: (column) => column);

  GeneratedColumn<double> get fat100 =>
      $composableBuilder(column: $table.fat100, builder: (column) => column);

  GeneratedColumn<bool> get isEstimate => $composableBuilder(
    column: $table.isEstimate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get userOverride => $composableBuilder(
    column: $table.userOverride,
    builder: (column) => column,
  );

  GeneratedColumn<double> get gramsPerPiece => $composableBuilder(
    column: $table.gramsPerPiece,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fibre100 =>
      $composableBuilder(column: $table.fibre100, builder: (column) => column);

  GeneratedColumn<double> get sodium100 =>
      $composableBuilder(column: $table.sodium100, builder: (column) => column);

  GeneratedColumn<double> get basisQuantity => $composableBuilder(
    column: $table.basisQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get basisUnit =>
      $composableBuilder(column: $table.basisUnit, builder: (column) => column);

  GeneratedColumn<double> get basisKcal =>
      $composableBuilder(column: $table.basisKcal, builder: (column) => column);

  GeneratedColumn<double> get basisProtein => $composableBuilder(
    column: $table.basisProtein,
    builder: (column) => column,
  );

  GeneratedColumn<double> get basisCarb =>
      $composableBuilder(column: $table.basisCarb, builder: (column) => column);

  GeneratedColumn<double> get basisFat =>
      $composableBuilder(column: $table.basisFat, builder: (column) => column);

  GeneratedColumn<double> get basisPhysicalGrams => $composableBuilder(
    column: $table.basisPhysicalGrams,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get basisNeedsReview => $composableBuilder(
    column: $table.basisNeedsReview,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<String> get sourceTitle => $composableBuilder(
    column: $table.sourceTitle,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get sourceRetrievedAt => $composableBuilder(
    column: $table.sourceRetrievedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceInferredFields => $composableBuilder(
    column: $table.sourceInferredFields,
    builder: (column) => column,
  );
}

class $$FoodCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodCacheTable,
          FoodCacheData,
          $$FoodCacheTableFilterComposer,
          $$FoodCacheTableOrderingComposer,
          $$FoodCacheTableAnnotationComposer,
          $$FoodCacheTableCreateCompanionBuilder,
          $$FoodCacheTableUpdateCompanionBuilder,
          (
            FoodCacheData,
            BaseReferences<_$AppDatabase, $FoodCacheTable, FoodCacheData>,
          ),
          FoodCacheData,
          PrefetchHooks Function()
        > {
  $$FoodCacheTableTableManager(_$AppDatabase db, $FoodCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<double> kcal100 = const Value.absent(),
                Value<double> protein100 = const Value.absent(),
                Value<double> carb100 = const Value.absent(),
                Value<double> fat100 = const Value.absent(),
                Value<bool> isEstimate = const Value.absent(),
                Value<bool> userOverride = const Value.absent(),
                Value<double?> gramsPerPiece = const Value.absent(),
                Value<double?> fibre100 = const Value.absent(),
                Value<double?> sodium100 = const Value.absent(),
                Value<double?> basisQuantity = const Value.absent(),
                Value<String?> basisUnit = const Value.absent(),
                Value<double?> basisKcal = const Value.absent(),
                Value<double?> basisProtein = const Value.absent(),
                Value<double?> basisCarb = const Value.absent(),
                Value<double?> basisFat = const Value.absent(),
                Value<double?> basisPhysicalGrams = const Value.absent(),
                Value<bool> basisNeedsReview = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<String?> sourceTitle = const Value.absent(),
                Value<DateTime?> sourceRetrievedAt = const Value.absent(),
                Value<String?> sourceInferredFields = const Value.absent(),
              }) => FoodCacheCompanion(
                id: id,
                name: name,
                source: source,
                kcal100: kcal100,
                protein100: protein100,
                carb100: carb100,
                fat100: fat100,
                isEstimate: isEstimate,
                userOverride: userOverride,
                gramsPerPiece: gramsPerPiece,
                fibre100: fibre100,
                sodium100: sodium100,
                basisQuantity: basisQuantity,
                basisUnit: basisUnit,
                basisKcal: basisKcal,
                basisProtein: basisProtein,
                basisCarb: basisCarb,
                basisFat: basisFat,
                basisPhysicalGrams: basisPhysicalGrams,
                basisNeedsReview: basisNeedsReview,
                sourceUrl: sourceUrl,
                sourceTitle: sourceTitle,
                sourceRetrievedAt: sourceRetrievedAt,
                sourceInferredFields: sourceInferredFields,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String source,
                required double kcal100,
                required double protein100,
                required double carb100,
                required double fat100,
                Value<bool> isEstimate = const Value.absent(),
                Value<bool> userOverride = const Value.absent(),
                Value<double?> gramsPerPiece = const Value.absent(),
                Value<double?> fibre100 = const Value.absent(),
                Value<double?> sodium100 = const Value.absent(),
                Value<double?> basisQuantity = const Value.absent(),
                Value<String?> basisUnit = const Value.absent(),
                Value<double?> basisKcal = const Value.absent(),
                Value<double?> basisProtein = const Value.absent(),
                Value<double?> basisCarb = const Value.absent(),
                Value<double?> basisFat = const Value.absent(),
                Value<double?> basisPhysicalGrams = const Value.absent(),
                Value<bool> basisNeedsReview = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<String?> sourceTitle = const Value.absent(),
                Value<DateTime?> sourceRetrievedAt = const Value.absent(),
                Value<String?> sourceInferredFields = const Value.absent(),
              }) => FoodCacheCompanion.insert(
                id: id,
                name: name,
                source: source,
                kcal100: kcal100,
                protein100: protein100,
                carb100: carb100,
                fat100: fat100,
                isEstimate: isEstimate,
                userOverride: userOverride,
                gramsPerPiece: gramsPerPiece,
                fibre100: fibre100,
                sodium100: sodium100,
                basisQuantity: basisQuantity,
                basisUnit: basisUnit,
                basisKcal: basisKcal,
                basisProtein: basisProtein,
                basisCarb: basisCarb,
                basisFat: basisFat,
                basisPhysicalGrams: basisPhysicalGrams,
                basisNeedsReview: basisNeedsReview,
                sourceUrl: sourceUrl,
                sourceTitle: sourceTitle,
                sourceRetrievedAt: sourceRetrievedAt,
                sourceInferredFields: sourceInferredFields,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoodCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodCacheTable,
      FoodCacheData,
      $$FoodCacheTableFilterComposer,
      $$FoodCacheTableOrderingComposer,
      $$FoodCacheTableAnnotationComposer,
      $$FoodCacheTableCreateCompanionBuilder,
      $$FoodCacheTableUpdateCompanionBuilder,
      (
        FoodCacheData,
        BaseReferences<_$AppDatabase, $FoodCacheTable, FoodCacheData>,
      ),
      FoodCacheData,
      PrefetchHooks Function()
    >;
typedef $$FoodUnitWeightsTableCreateCompanionBuilder =
    FoodUnitWeightsCompanion Function({
      required String foodKey,
      required String foodName,
      required String unit,
      required double gramsPerUnit,
      required String kind,
      required String sourceUrl,
      required String sourceTitle,
      required DateTime sourceRetrievedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$FoodUnitWeightsTableUpdateCompanionBuilder =
    FoodUnitWeightsCompanion Function({
      Value<String> foodKey,
      Value<String> foodName,
      Value<String> unit,
      Value<double> gramsPerUnit,
      Value<String> kind,
      Value<String> sourceUrl,
      Value<String> sourceTitle,
      Value<DateTime> sourceRetrievedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$FoodUnitWeightsTableFilterComposer
    extends Composer<_$AppDatabase, $FoodUnitWeightsTable> {
  $$FoodUnitWeightsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get foodKey => $composableBuilder(
    column: $table.foodKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foodName => $composableBuilder(
    column: $table.foodName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gramsPerUnit => $composableBuilder(
    column: $table.gramsPerUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceTitle => $composableBuilder(
    column: $table.sourceTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sourceRetrievedAt => $composableBuilder(
    column: $table.sourceRetrievedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoodUnitWeightsTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodUnitWeightsTable> {
  $$FoodUnitWeightsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get foodKey => $composableBuilder(
    column: $table.foodKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foodName => $composableBuilder(
    column: $table.foodName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gramsPerUnit => $composableBuilder(
    column: $table.gramsPerUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceTitle => $composableBuilder(
    column: $table.sourceTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sourceRetrievedAt => $composableBuilder(
    column: $table.sourceRetrievedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodUnitWeightsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodUnitWeightsTable> {
  $$FoodUnitWeightsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get foodKey =>
      $composableBuilder(column: $table.foodKey, builder: (column) => column);

  GeneratedColumn<String> get foodName =>
      $composableBuilder(column: $table.foodName, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get gramsPerUnit => $composableBuilder(
    column: $table.gramsPerUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<String> get sourceTitle => $composableBuilder(
    column: $table.sourceTitle,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get sourceRetrievedAt => $composableBuilder(
    column: $table.sourceRetrievedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FoodUnitWeightsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodUnitWeightsTable,
          FoodUnitWeightRow,
          $$FoodUnitWeightsTableFilterComposer,
          $$FoodUnitWeightsTableOrderingComposer,
          $$FoodUnitWeightsTableAnnotationComposer,
          $$FoodUnitWeightsTableCreateCompanionBuilder,
          $$FoodUnitWeightsTableUpdateCompanionBuilder,
          (
            FoodUnitWeightRow,
            BaseReferences<
              _$AppDatabase,
              $FoodUnitWeightsTable,
              FoodUnitWeightRow
            >,
          ),
          FoodUnitWeightRow,
          PrefetchHooks Function()
        > {
  $$FoodUnitWeightsTableTableManager(
    _$AppDatabase db,
    $FoodUnitWeightsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodUnitWeightsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodUnitWeightsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodUnitWeightsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> foodKey = const Value.absent(),
                Value<String> foodName = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<double> gramsPerUnit = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> sourceUrl = const Value.absent(),
                Value<String> sourceTitle = const Value.absent(),
                Value<DateTime> sourceRetrievedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoodUnitWeightsCompanion(
                foodKey: foodKey,
                foodName: foodName,
                unit: unit,
                gramsPerUnit: gramsPerUnit,
                kind: kind,
                sourceUrl: sourceUrl,
                sourceTitle: sourceTitle,
                sourceRetrievedAt: sourceRetrievedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String foodKey,
                required String foodName,
                required String unit,
                required double gramsPerUnit,
                required String kind,
                required String sourceUrl,
                required String sourceTitle,
                required DateTime sourceRetrievedAt,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoodUnitWeightsCompanion.insert(
                foodKey: foodKey,
                foodName: foodName,
                unit: unit,
                gramsPerUnit: gramsPerUnit,
                kind: kind,
                sourceUrl: sourceUrl,
                sourceTitle: sourceTitle,
                sourceRetrievedAt: sourceRetrievedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoodUnitWeightsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodUnitWeightsTable,
      FoodUnitWeightRow,
      $$FoodUnitWeightsTableFilterComposer,
      $$FoodUnitWeightsTableOrderingComposer,
      $$FoodUnitWeightsTableAnnotationComposer,
      $$FoodUnitWeightsTableCreateCompanionBuilder,
      $$FoodUnitWeightsTableUpdateCompanionBuilder,
      (
        FoodUnitWeightRow,
        BaseReferences<_$AppDatabase, $FoodUnitWeightsTable, FoodUnitWeightRow>,
      ),
      FoodUnitWeightRow,
      PrefetchHooks Function()
    >;
typedef $$LogEntriesTableCreateCompanionBuilder =
    LogEntriesCompanion Function({
      Value<int> id,
      required String date,
      required String foodName,
      required double grams,
      required double kcal,
      required double protein,
      required double carb,
      required double fat,
      Value<double?> fibre,
      required String source,
      Value<int?> recipeId,
      Value<double?> portionQuantity,
      Value<String?> portionUnit,
      Value<double?> portionWeightGramsPerUnit,
      Value<String?> portionWeightUnit,
      Value<bool?> portionWeightIsEstimate,
      Value<String?> portionWeightSourceUrl,
      Value<String?> portionWeightSourceTitle,
      Value<DateTime?> portionWeightSourceRetrievedAt,
    });
typedef $$LogEntriesTableUpdateCompanionBuilder =
    LogEntriesCompanion Function({
      Value<int> id,
      Value<String> date,
      Value<String> foodName,
      Value<double> grams,
      Value<double> kcal,
      Value<double> protein,
      Value<double> carb,
      Value<double> fat,
      Value<double?> fibre,
      Value<String> source,
      Value<int?> recipeId,
      Value<double?> portionQuantity,
      Value<String?> portionUnit,
      Value<double?> portionWeightGramsPerUnit,
      Value<String?> portionWeightUnit,
      Value<bool?> portionWeightIsEstimate,
      Value<String?> portionWeightSourceUrl,
      Value<String?> portionWeightSourceTitle,
      Value<DateTime?> portionWeightSourceRetrievedAt,
    });

class $$LogEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LogEntriesTable> {
  $$LogEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foodName => $composableBuilder(
    column: $table.foodName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carb => $composableBuilder(
    column: $table.carb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fibre => $composableBuilder(
    column: $table.fibre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get portionQuantity => $composableBuilder(
    column: $table.portionQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get portionUnit => $composableBuilder(
    column: $table.portionUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get portionWeightGramsPerUnit => $composableBuilder(
    column: $table.portionWeightGramsPerUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get portionWeightUnit => $composableBuilder(
    column: $table.portionWeightUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get portionWeightIsEstimate => $composableBuilder(
    column: $table.portionWeightIsEstimate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get portionWeightSourceUrl => $composableBuilder(
    column: $table.portionWeightSourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get portionWeightSourceTitle => $composableBuilder(
    column: $table.portionWeightSourceTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get portionWeightSourceRetrievedAt =>
      $composableBuilder(
        column: $table.portionWeightSourceRetrievedAt,
        builder: (column) => ColumnFilters(column),
      );
}

class $$LogEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LogEntriesTable> {
  $$LogEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foodName => $composableBuilder(
    column: $table.foodName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carb => $composableBuilder(
    column: $table.carb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fibre => $composableBuilder(
    column: $table.fibre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get portionQuantity => $composableBuilder(
    column: $table.portionQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get portionUnit => $composableBuilder(
    column: $table.portionUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get portionWeightGramsPerUnit => $composableBuilder(
    column: $table.portionWeightGramsPerUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get portionWeightUnit => $composableBuilder(
    column: $table.portionWeightUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get portionWeightIsEstimate => $composableBuilder(
    column: $table.portionWeightIsEstimate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get portionWeightSourceUrl => $composableBuilder(
    column: $table.portionWeightSourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get portionWeightSourceTitle => $composableBuilder(
    column: $table.portionWeightSourceTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get portionWeightSourceRetrievedAt =>
      $composableBuilder(
        column: $table.portionWeightSourceRetrievedAt,
        builder: (column) => ColumnOrderings(column),
      );
}

class $$LogEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LogEntriesTable> {
  $$LogEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get foodName =>
      $composableBuilder(column: $table.foodName, builder: (column) => column);

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<double> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<double> get protein =>
      $composableBuilder(column: $table.protein, builder: (column) => column);

  GeneratedColumn<double> get carb =>
      $composableBuilder(column: $table.carb, builder: (column) => column);

  GeneratedColumn<double> get fat =>
      $composableBuilder(column: $table.fat, builder: (column) => column);

  GeneratedColumn<double> get fibre =>
      $composableBuilder(column: $table.fibre, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get recipeId =>
      $composableBuilder(column: $table.recipeId, builder: (column) => column);

  GeneratedColumn<double> get portionQuantity => $composableBuilder(
    column: $table.portionQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get portionUnit => $composableBuilder(
    column: $table.portionUnit,
    builder: (column) => column,
  );

  GeneratedColumn<double> get portionWeightGramsPerUnit => $composableBuilder(
    column: $table.portionWeightGramsPerUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get portionWeightUnit => $composableBuilder(
    column: $table.portionWeightUnit,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get portionWeightIsEstimate => $composableBuilder(
    column: $table.portionWeightIsEstimate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get portionWeightSourceUrl => $composableBuilder(
    column: $table.portionWeightSourceUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get portionWeightSourceTitle => $composableBuilder(
    column: $table.portionWeightSourceTitle,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get portionWeightSourceRetrievedAt =>
      $composableBuilder(
        column: $table.portionWeightSourceRetrievedAt,
        builder: (column) => column,
      );
}

class $$LogEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LogEntriesTable,
          LogEntry,
          $$LogEntriesTableFilterComposer,
          $$LogEntriesTableOrderingComposer,
          $$LogEntriesTableAnnotationComposer,
          $$LogEntriesTableCreateCompanionBuilder,
          $$LogEntriesTableUpdateCompanionBuilder,
          (LogEntry, BaseReferences<_$AppDatabase, $LogEntriesTable, LogEntry>),
          LogEntry,
          PrefetchHooks Function()
        > {
  $$LogEntriesTableTableManager(_$AppDatabase db, $LogEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LogEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LogEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LogEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> foodName = const Value.absent(),
                Value<double> grams = const Value.absent(),
                Value<double> kcal = const Value.absent(),
                Value<double> protein = const Value.absent(),
                Value<double> carb = const Value.absent(),
                Value<double> fat = const Value.absent(),
                Value<double?> fibre = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int?> recipeId = const Value.absent(),
                Value<double?> portionQuantity = const Value.absent(),
                Value<String?> portionUnit = const Value.absent(),
                Value<double?> portionWeightGramsPerUnit = const Value.absent(),
                Value<String?> portionWeightUnit = const Value.absent(),
                Value<bool?> portionWeightIsEstimate = const Value.absent(),
                Value<String?> portionWeightSourceUrl = const Value.absent(),
                Value<String?> portionWeightSourceTitle = const Value.absent(),
                Value<DateTime?> portionWeightSourceRetrievedAt =
                    const Value.absent(),
              }) => LogEntriesCompanion(
                id: id,
                date: date,
                foodName: foodName,
                grams: grams,
                kcal: kcal,
                protein: protein,
                carb: carb,
                fat: fat,
                fibre: fibre,
                source: source,
                recipeId: recipeId,
                portionQuantity: portionQuantity,
                portionUnit: portionUnit,
                portionWeightGramsPerUnit: portionWeightGramsPerUnit,
                portionWeightUnit: portionWeightUnit,
                portionWeightIsEstimate: portionWeightIsEstimate,
                portionWeightSourceUrl: portionWeightSourceUrl,
                portionWeightSourceTitle: portionWeightSourceTitle,
                portionWeightSourceRetrievedAt: portionWeightSourceRetrievedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String date,
                required String foodName,
                required double grams,
                required double kcal,
                required double protein,
                required double carb,
                required double fat,
                Value<double?> fibre = const Value.absent(),
                required String source,
                Value<int?> recipeId = const Value.absent(),
                Value<double?> portionQuantity = const Value.absent(),
                Value<String?> portionUnit = const Value.absent(),
                Value<double?> portionWeightGramsPerUnit = const Value.absent(),
                Value<String?> portionWeightUnit = const Value.absent(),
                Value<bool?> portionWeightIsEstimate = const Value.absent(),
                Value<String?> portionWeightSourceUrl = const Value.absent(),
                Value<String?> portionWeightSourceTitle = const Value.absent(),
                Value<DateTime?> portionWeightSourceRetrievedAt =
                    const Value.absent(),
              }) => LogEntriesCompanion.insert(
                id: id,
                date: date,
                foodName: foodName,
                grams: grams,
                kcal: kcal,
                protein: protein,
                carb: carb,
                fat: fat,
                fibre: fibre,
                source: source,
                recipeId: recipeId,
                portionQuantity: portionQuantity,
                portionUnit: portionUnit,
                portionWeightGramsPerUnit: portionWeightGramsPerUnit,
                portionWeightUnit: portionWeightUnit,
                portionWeightIsEstimate: portionWeightIsEstimate,
                portionWeightSourceUrl: portionWeightSourceUrl,
                portionWeightSourceTitle: portionWeightSourceTitle,
                portionWeightSourceRetrievedAt: portionWeightSourceRetrievedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LogEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LogEntriesTable,
      LogEntry,
      $$LogEntriesTableFilterComposer,
      $$LogEntriesTableOrderingComposer,
      $$LogEntriesTableAnnotationComposer,
      $$LogEntriesTableCreateCompanionBuilder,
      $$LogEntriesTableUpdateCompanionBuilder,
      (LogEntry, BaseReferences<_$AppDatabase, $LogEntriesTable, LogEntry>),
      LogEntry,
      PrefetchHooks Function()
    >;
typedef $$DailyTargetsTableTableCreateCompanionBuilder =
    DailyTargetsTableCompanion Function({
      required String scope,
      required double kcal,
      required double protein,
      required double carb,
      required double fat,
      Value<int> rowid,
    });
typedef $$DailyTargetsTableTableUpdateCompanionBuilder =
    DailyTargetsTableCompanion Function({
      Value<String> scope,
      Value<double> kcal,
      Value<double> protein,
      Value<double> carb,
      Value<double> fat,
      Value<int> rowid,
    });

class $$DailyTargetsTableTableFilterComposer
    extends Composer<_$AppDatabase, $DailyTargetsTableTable> {
  $$DailyTargetsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carb => $composableBuilder(
    column: $table.carb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyTargetsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyTargetsTableTable> {
  $$DailyTargetsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carb => $composableBuilder(
    column: $table.carb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyTargetsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyTargetsTableTable> {
  $$DailyTargetsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<double> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<double> get protein =>
      $composableBuilder(column: $table.protein, builder: (column) => column);

  GeneratedColumn<double> get carb =>
      $composableBuilder(column: $table.carb, builder: (column) => column);

  GeneratedColumn<double> get fat =>
      $composableBuilder(column: $table.fat, builder: (column) => column);
}

class $$DailyTargetsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyTargetsTableTable,
          DailyTargetsTableData,
          $$DailyTargetsTableTableFilterComposer,
          $$DailyTargetsTableTableOrderingComposer,
          $$DailyTargetsTableTableAnnotationComposer,
          $$DailyTargetsTableTableCreateCompanionBuilder,
          $$DailyTargetsTableTableUpdateCompanionBuilder,
          (
            DailyTargetsTableData,
            BaseReferences<
              _$AppDatabase,
              $DailyTargetsTableTable,
              DailyTargetsTableData
            >,
          ),
          DailyTargetsTableData,
          PrefetchHooks Function()
        > {
  $$DailyTargetsTableTableTableManager(
    _$AppDatabase db,
    $DailyTargetsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyTargetsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyTargetsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyTargetsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> scope = const Value.absent(),
                Value<double> kcal = const Value.absent(),
                Value<double> protein = const Value.absent(),
                Value<double> carb = const Value.absent(),
                Value<double> fat = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyTargetsTableCompanion(
                scope: scope,
                kcal: kcal,
                protein: protein,
                carb: carb,
                fat: fat,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String scope,
                required double kcal,
                required double protein,
                required double carb,
                required double fat,
                Value<int> rowid = const Value.absent(),
              }) => DailyTargetsTableCompanion.insert(
                scope: scope,
                kcal: kcal,
                protein: protein,
                carb: carb,
                fat: fat,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyTargetsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyTargetsTableTable,
      DailyTargetsTableData,
      $$DailyTargetsTableTableFilterComposer,
      $$DailyTargetsTableTableOrderingComposer,
      $$DailyTargetsTableTableAnnotationComposer,
      $$DailyTargetsTableTableCreateCompanionBuilder,
      $$DailyTargetsTableTableUpdateCompanionBuilder,
      (
        DailyTargetsTableData,
        BaseReferences<
          _$AppDatabase,
          $DailyTargetsTableTable,
          DailyTargetsTableData
        >,
      ),
      DailyTargetsTableData,
      PrefetchHooks Function()
    >;
typedef $$AdaptiveTargetsTableCreateCompanionBuilder =
    AdaptiveTargetsCompanion Function({
      Value<int> id,
      required String effectiveFrom,
      required String calculatedThrough,
      required double kcal,
      required double protein,
      required double carb,
      required double fat,
      required String windowStart,
      required int qualifiedIntakeDays,
      required int weightObservationCount,
      required double estimatedMaintenanceKcal,
      required double appliedAdjustmentKcal,
      required String reason,
      Value<String?> goal,
      Value<DateTime> createdAt,
    });
typedef $$AdaptiveTargetsTableUpdateCompanionBuilder =
    AdaptiveTargetsCompanion Function({
      Value<int> id,
      Value<String> effectiveFrom,
      Value<String> calculatedThrough,
      Value<double> kcal,
      Value<double> protein,
      Value<double> carb,
      Value<double> fat,
      Value<String> windowStart,
      Value<int> qualifiedIntakeDays,
      Value<int> weightObservationCount,
      Value<double> estimatedMaintenanceKcal,
      Value<double> appliedAdjustmentKcal,
      Value<String> reason,
      Value<String?> goal,
      Value<DateTime> createdAt,
    });

class $$AdaptiveTargetsTableFilterComposer
    extends Composer<_$AppDatabase, $AdaptiveTargetsTable> {
  $$AdaptiveTargetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get calculatedThrough => $composableBuilder(
    column: $table.calculatedThrough,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carb => $composableBuilder(
    column: $table.carb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get windowStart => $composableBuilder(
    column: $table.windowStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qualifiedIntakeDays => $composableBuilder(
    column: $table.qualifiedIntakeDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weightObservationCount => $composableBuilder(
    column: $table.weightObservationCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get estimatedMaintenanceKcal => $composableBuilder(
    column: $table.estimatedMaintenanceKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get appliedAdjustmentKcal => $composableBuilder(
    column: $table.appliedAdjustmentKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goal => $composableBuilder(
    column: $table.goal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AdaptiveTargetsTableOrderingComposer
    extends Composer<_$AppDatabase, $AdaptiveTargetsTable> {
  $$AdaptiveTargetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get calculatedThrough => $composableBuilder(
    column: $table.calculatedThrough,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carb => $composableBuilder(
    column: $table.carb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get windowStart => $composableBuilder(
    column: $table.windowStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qualifiedIntakeDays => $composableBuilder(
    column: $table.qualifiedIntakeDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weightObservationCount => $composableBuilder(
    column: $table.weightObservationCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get estimatedMaintenanceKcal => $composableBuilder(
    column: $table.estimatedMaintenanceKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get appliedAdjustmentKcal => $composableBuilder(
    column: $table.appliedAdjustmentKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goal => $composableBuilder(
    column: $table.goal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AdaptiveTargetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AdaptiveTargetsTable> {
  $$AdaptiveTargetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => column,
  );

  GeneratedColumn<String> get calculatedThrough => $composableBuilder(
    column: $table.calculatedThrough,
    builder: (column) => column,
  );

  GeneratedColumn<double> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<double> get protein =>
      $composableBuilder(column: $table.protein, builder: (column) => column);

  GeneratedColumn<double> get carb =>
      $composableBuilder(column: $table.carb, builder: (column) => column);

  GeneratedColumn<double> get fat =>
      $composableBuilder(column: $table.fat, builder: (column) => column);

  GeneratedColumn<String> get windowStart => $composableBuilder(
    column: $table.windowStart,
    builder: (column) => column,
  );

  GeneratedColumn<int> get qualifiedIntakeDays => $composableBuilder(
    column: $table.qualifiedIntakeDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get weightObservationCount => $composableBuilder(
    column: $table.weightObservationCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get estimatedMaintenanceKcal => $composableBuilder(
    column: $table.estimatedMaintenanceKcal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get appliedAdjustmentKcal => $composableBuilder(
    column: $table.appliedAdjustmentKcal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get goal =>
      $composableBuilder(column: $table.goal, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AdaptiveTargetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AdaptiveTargetsTable,
          AdaptiveTarget,
          $$AdaptiveTargetsTableFilterComposer,
          $$AdaptiveTargetsTableOrderingComposer,
          $$AdaptiveTargetsTableAnnotationComposer,
          $$AdaptiveTargetsTableCreateCompanionBuilder,
          $$AdaptiveTargetsTableUpdateCompanionBuilder,
          (
            AdaptiveTarget,
            BaseReferences<
              _$AppDatabase,
              $AdaptiveTargetsTable,
              AdaptiveTarget
            >,
          ),
          AdaptiveTarget,
          PrefetchHooks Function()
        > {
  $$AdaptiveTargetsTableTableManager(
    _$AppDatabase db,
    $AdaptiveTargetsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdaptiveTargetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AdaptiveTargetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AdaptiveTargetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> effectiveFrom = const Value.absent(),
                Value<String> calculatedThrough = const Value.absent(),
                Value<double> kcal = const Value.absent(),
                Value<double> protein = const Value.absent(),
                Value<double> carb = const Value.absent(),
                Value<double> fat = const Value.absent(),
                Value<String> windowStart = const Value.absent(),
                Value<int> qualifiedIntakeDays = const Value.absent(),
                Value<int> weightObservationCount = const Value.absent(),
                Value<double> estimatedMaintenanceKcal = const Value.absent(),
                Value<double> appliedAdjustmentKcal = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String?> goal = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => AdaptiveTargetsCompanion(
                id: id,
                effectiveFrom: effectiveFrom,
                calculatedThrough: calculatedThrough,
                kcal: kcal,
                protein: protein,
                carb: carb,
                fat: fat,
                windowStart: windowStart,
                qualifiedIntakeDays: qualifiedIntakeDays,
                weightObservationCount: weightObservationCount,
                estimatedMaintenanceKcal: estimatedMaintenanceKcal,
                appliedAdjustmentKcal: appliedAdjustmentKcal,
                reason: reason,
                goal: goal,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String effectiveFrom,
                required String calculatedThrough,
                required double kcal,
                required double protein,
                required double carb,
                required double fat,
                required String windowStart,
                required int qualifiedIntakeDays,
                required int weightObservationCount,
                required double estimatedMaintenanceKcal,
                required double appliedAdjustmentKcal,
                required String reason,
                Value<String?> goal = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => AdaptiveTargetsCompanion.insert(
                id: id,
                effectiveFrom: effectiveFrom,
                calculatedThrough: calculatedThrough,
                kcal: kcal,
                protein: protein,
                carb: carb,
                fat: fat,
                windowStart: windowStart,
                qualifiedIntakeDays: qualifiedIntakeDays,
                weightObservationCount: weightObservationCount,
                estimatedMaintenanceKcal: estimatedMaintenanceKcal,
                appliedAdjustmentKcal: appliedAdjustmentKcal,
                reason: reason,
                goal: goal,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AdaptiveTargetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AdaptiveTargetsTable,
      AdaptiveTarget,
      $$AdaptiveTargetsTableFilterComposer,
      $$AdaptiveTargetsTableOrderingComposer,
      $$AdaptiveTargetsTableAnnotationComposer,
      $$AdaptiveTargetsTableCreateCompanionBuilder,
      $$AdaptiveTargetsTableUpdateCompanionBuilder,
      (
        AdaptiveTarget,
        BaseReferences<_$AppDatabase, $AdaptiveTargetsTable, AdaptiveTarget>,
      ),
      AdaptiveTarget,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$GroceryItemsTableCreateCompanionBuilder =
    GroceryItemsCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> detail,
      Value<bool> checked,
      Value<DateTime> createdAt,
    });
typedef $$GroceryItemsTableUpdateCompanionBuilder =
    GroceryItemsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> detail,
      Value<bool> checked,
      Value<DateTime> createdAt,
    });

class $$GroceryItemsTableFilterComposer
    extends Composer<_$AppDatabase, $GroceryItemsTable> {
  $$GroceryItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get checked => $composableBuilder(
    column: $table.checked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GroceryItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $GroceryItemsTable> {
  $$GroceryItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get checked => $composableBuilder(
    column: $table.checked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GroceryItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroceryItemsTable> {
  $$GroceryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => column);

  GeneratedColumn<bool> get checked =>
      $composableBuilder(column: $table.checked, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$GroceryItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroceryItemsTable,
          GroceryItem,
          $$GroceryItemsTableFilterComposer,
          $$GroceryItemsTableOrderingComposer,
          $$GroceryItemsTableAnnotationComposer,
          $$GroceryItemsTableCreateCompanionBuilder,
          $$GroceryItemsTableUpdateCompanionBuilder,
          (
            GroceryItem,
            BaseReferences<_$AppDatabase, $GroceryItemsTable, GroceryItem>,
          ),
          GroceryItem,
          PrefetchHooks Function()
        > {
  $$GroceryItemsTableTableManager(_$AppDatabase db, $GroceryItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroceryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroceryItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroceryItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> detail = const Value.absent(),
                Value<bool> checked = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => GroceryItemsCompanion(
                id: id,
                name: name,
                detail: detail,
                checked: checked,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> detail = const Value.absent(),
                Value<bool> checked = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => GroceryItemsCompanion.insert(
                id: id,
                name: name,
                detail: detail,
                checked: checked,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GroceryItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroceryItemsTable,
      GroceryItem,
      $$GroceryItemsTableFilterComposer,
      $$GroceryItemsTableOrderingComposer,
      $$GroceryItemsTableAnnotationComposer,
      $$GroceryItemsTableCreateCompanionBuilder,
      $$GroceryItemsTableUpdateCompanionBuilder,
      (
        GroceryItem,
        BaseReferences<_$AppDatabase, $GroceryItemsTable, GroceryItem>,
      ),
      GroceryItem,
      PrefetchHooks Function()
    >;
typedef $$WeightEntriesTableCreateCompanionBuilder =
    WeightEntriesCompanion Function({
      Value<int> id,
      required String date,
      required double kg,
    });
typedef $$WeightEntriesTableUpdateCompanionBuilder =
    WeightEntriesCompanion Function({
      Value<int> id,
      Value<String> date,
      Value<double> kg,
    });

class $$WeightEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kg => $composableBuilder(
    column: $table.kg,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeightEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kg => $composableBuilder(
    column: $table.kg,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeightEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get kg =>
      $composableBuilder(column: $table.kg, builder: (column) => column);
}

class $$WeightEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeightEntriesTable,
          WeightEntry,
          $$WeightEntriesTableFilterComposer,
          $$WeightEntriesTableOrderingComposer,
          $$WeightEntriesTableAnnotationComposer,
          $$WeightEntriesTableCreateCompanionBuilder,
          $$WeightEntriesTableUpdateCompanionBuilder,
          (
            WeightEntry,
            BaseReferences<_$AppDatabase, $WeightEntriesTable, WeightEntry>,
          ),
          WeightEntry,
          PrefetchHooks Function()
        > {
  $$WeightEntriesTableTableManager(_$AppDatabase db, $WeightEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeightEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeightEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeightEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<double> kg = const Value.absent(),
              }) => WeightEntriesCompanion(id: id, date: date, kg: kg),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String date,
                required double kg,
              }) => WeightEntriesCompanion.insert(id: id, date: date, kg: kg),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeightEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeightEntriesTable,
      WeightEntry,
      $$WeightEntriesTableFilterComposer,
      $$WeightEntriesTableOrderingComposer,
      $$WeightEntriesTableAnnotationComposer,
      $$WeightEntriesTableCreateCompanionBuilder,
      $$WeightEntriesTableUpdateCompanionBuilder,
      (
        WeightEntry,
        BaseReferences<_$AppDatabase, $WeightEntriesTable, WeightEntry>,
      ),
      WeightEntry,
      PrefetchHooks Function()
    >;
typedef $$ExercisesTableCreateCompanionBuilder =
    ExercisesCompanion Function({
      Value<int> id,
      Value<String?> slug,
      required String name,
      required String category,
      Value<String?> primaryMuscle,
      Value<String?> secondaryMuscles,
      Value<String?> equipment,
      Value<String?> description,
      Value<bool> tracksWeight,
      Value<bool> tracksReps,
      Value<bool> tracksDuration,
      Value<bool> tracksDistance,
      Value<bool> isCustom,
      Value<DateTime> createdAt,
    });
typedef $$ExercisesTableUpdateCompanionBuilder =
    ExercisesCompanion Function({
      Value<int> id,
      Value<String?> slug,
      Value<String> name,
      Value<String> category,
      Value<String?> primaryMuscle,
      Value<String?> secondaryMuscles,
      Value<String?> equipment,
      Value<String?> description,
      Value<bool> tracksWeight,
      Value<bool> tracksReps,
      Value<bool> tracksDuration,
      Value<bool> tracksDistance,
      Value<bool> isCustom,
      Value<DateTime> createdAt,
    });

final class $$ExercisesTableReferences
    extends BaseReferences<_$AppDatabase, $ExercisesTable, Exercise> {
  $$ExercisesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SetEntriesTable, List<SetEntry>>
  _setEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.setEntries,
    aliasName: $_aliasNameGenerator(db.exercises.id, db.setEntries.exerciseId),
  );

  $$SetEntriesTableProcessedTableManager get setEntriesRefs {
    final manager = $$SetEntriesTableTableManager(
      $_db,
      $_db.setEntries,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_setEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TemplateExercisesTable, List<TemplateExercise>>
  _templateExercisesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.templateExercises,
        aliasName: $_aliasNameGenerator(
          db.exercises.id,
          db.templateExercises.exerciseId,
        ),
      );

  $$TemplateExercisesTableProcessedTableManager get templateExercisesRefs {
    final manager = $$TemplateExercisesTableTableManager(
      $_db,
      $_db.templateExercises,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _templateExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primaryMuscle => $composableBuilder(
    column: $table.primaryMuscle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get secondaryMuscles => $composableBuilder(
    column: $table.secondaryMuscles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get tracksWeight => $composableBuilder(
    column: $table.tracksWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get tracksReps => $composableBuilder(
    column: $table.tracksReps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get tracksDuration => $composableBuilder(
    column: $table.tracksDuration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get tracksDistance => $composableBuilder(
    column: $table.tracksDistance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> setEntriesRefs(
    Expression<bool> Function($$SetEntriesTableFilterComposer f) f,
  ) {
    final $$SetEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setEntries,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetEntriesTableFilterComposer(
            $db: $db,
            $table: $db.setEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> templateExercisesRefs(
    Expression<bool> Function($$TemplateExercisesTableFilterComposer f) f,
  ) {
    final $$TemplateExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateExercises,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateExercisesTableFilterComposer(
            $db: $db,
            $table: $db.templateExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primaryMuscle => $composableBuilder(
    column: $table.primaryMuscle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get secondaryMuscles => $composableBuilder(
    column: $table.secondaryMuscles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tracksWeight => $composableBuilder(
    column: $table.tracksWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tracksReps => $composableBuilder(
    column: $table.tracksReps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tracksDuration => $composableBuilder(
    column: $table.tracksDuration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tracksDistance => $composableBuilder(
    column: $table.tracksDistance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get primaryMuscle => $composableBuilder(
    column: $table.primaryMuscle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get secondaryMuscles => $composableBuilder(
    column: $table.secondaryMuscles,
    builder: (column) => column,
  );

  GeneratedColumn<String> get equipment =>
      $composableBuilder(column: $table.equipment, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get tracksWeight => $composableBuilder(
    column: $table.tracksWeight,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get tracksReps => $composableBuilder(
    column: $table.tracksReps,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get tracksDuration => $composableBuilder(
    column: $table.tracksDuration,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get tracksDistance => $composableBuilder(
    column: $table.tracksDistance,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCustom =>
      $composableBuilder(column: $table.isCustom, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> setEntriesRefs<T extends Object>(
    Expression<T> Function($$SetEntriesTableAnnotationComposer a) f,
  ) {
    final $$SetEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setEntries,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.setEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> templateExercisesRefs<T extends Object>(
    Expression<T> Function($$TemplateExercisesTableAnnotationComposer a) f,
  ) {
    final $$TemplateExercisesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.templateExercises,
          getReferencedColumn: (t) => t.exerciseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TemplateExercisesTableAnnotationComposer(
                $db: $db,
                $table: $db.templateExercises,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExercisesTable,
          Exercise,
          $$ExercisesTableFilterComposer,
          $$ExercisesTableOrderingComposer,
          $$ExercisesTableAnnotationComposer,
          $$ExercisesTableCreateCompanionBuilder,
          $$ExercisesTableUpdateCompanionBuilder,
          (Exercise, $$ExercisesTableReferences),
          Exercise,
          PrefetchHooks Function({
            bool setEntriesRefs,
            bool templateExercisesRefs,
          })
        > {
  $$ExercisesTableTableManager(_$AppDatabase db, $ExercisesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> slug = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> primaryMuscle = const Value.absent(),
                Value<String?> secondaryMuscles = const Value.absent(),
                Value<String?> equipment = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> tracksWeight = const Value.absent(),
                Value<bool> tracksReps = const Value.absent(),
                Value<bool> tracksDuration = const Value.absent(),
                Value<bool> tracksDistance = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ExercisesCompanion(
                id: id,
                slug: slug,
                name: name,
                category: category,
                primaryMuscle: primaryMuscle,
                secondaryMuscles: secondaryMuscles,
                equipment: equipment,
                description: description,
                tracksWeight: tracksWeight,
                tracksReps: tracksReps,
                tracksDuration: tracksDuration,
                tracksDistance: tracksDistance,
                isCustom: isCustom,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> slug = const Value.absent(),
                required String name,
                required String category,
                Value<String?> primaryMuscle = const Value.absent(),
                Value<String?> secondaryMuscles = const Value.absent(),
                Value<String?> equipment = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> tracksWeight = const Value.absent(),
                Value<bool> tracksReps = const Value.absent(),
                Value<bool> tracksDuration = const Value.absent(),
                Value<bool> tracksDistance = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ExercisesCompanion.insert(
                id: id,
                slug: slug,
                name: name,
                category: category,
                primaryMuscle: primaryMuscle,
                secondaryMuscles: secondaryMuscles,
                equipment: equipment,
                description: description,
                tracksWeight: tracksWeight,
                tracksReps: tracksReps,
                tracksDuration: tracksDuration,
                tracksDistance: tracksDistance,
                isCustom: isCustom,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({setEntriesRefs = false, templateExercisesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (setEntriesRefs) db.setEntries,
                    if (templateExercisesRefs) db.templateExercises,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (setEntriesRefs)
                        await $_getPrefetchedData<
                          Exercise,
                          $ExercisesTable,
                          SetEntry
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._setEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).setEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (templateExercisesRefs)
                        await $_getPrefetchedData<
                          Exercise,
                          $ExercisesTable,
                          TemplateExercise
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._templateExercisesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).templateExercisesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExercisesTable,
      Exercise,
      $$ExercisesTableFilterComposer,
      $$ExercisesTableOrderingComposer,
      $$ExercisesTableAnnotationComposer,
      $$ExercisesTableCreateCompanionBuilder,
      $$ExercisesTableUpdateCompanionBuilder,
      (Exercise, $$ExercisesTableReferences),
      Exercise,
      PrefetchHooks Function({bool setEntriesRefs, bool templateExercisesRefs})
    >;
typedef $$WorkoutSessionsTableCreateCompanionBuilder =
    WorkoutSessionsCompanion Function({
      Value<int> id,
      required String date,
      Value<int?> dayId,
      required String name,
      Value<DateTime?> startedAt,
      Value<DateTime?> completedAt,
      Value<int?> durationSec,
      Value<int?> perceivedEffort,
      Value<String?> notes,
    });
typedef $$WorkoutSessionsTableUpdateCompanionBuilder =
    WorkoutSessionsCompanion Function({
      Value<int> id,
      Value<String> date,
      Value<int?> dayId,
      Value<String> name,
      Value<DateTime?> startedAt,
      Value<DateTime?> completedAt,
      Value<int?> durationSec,
      Value<int?> perceivedEffort,
      Value<String?> notes,
    });

final class $$WorkoutSessionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $WorkoutSessionsTable, WorkoutSession> {
  $$WorkoutSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$SetEntriesTable, List<SetEntry>>
  _setEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.setEntries,
    aliasName: $_aliasNameGenerator(
      db.workoutSessions.id,
      db.setEntries.sessionId,
    ),
  );

  $$SetEntriesTableProcessedTableManager get setEntriesRefs {
    final manager = $$SetEntriesTableTableManager(
      $_db,
      $_db.setEntries,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_setEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkoutSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayId => $composableBuilder(
    column: $table.dayId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get perceivedEffort => $composableBuilder(
    column: $table.perceivedEffort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> setEntriesRefs(
    Expression<bool> Function($$SetEntriesTableFilterComposer f) f,
  ) {
    final $$SetEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setEntries,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetEntriesTableFilterComposer(
            $db: $db,
            $table: $db.setEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayId => $composableBuilder(
    column: $table.dayId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get perceivedEffort => $composableBuilder(
    column: $table.perceivedEffort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkoutSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get dayId =>
      $composableBuilder(column: $table.dayId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => column,
  );

  GeneratedColumn<int> get perceivedEffort => $composableBuilder(
    column: $table.perceivedEffort,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  Expression<T> setEntriesRefs<T extends Object>(
    Expression<T> Function($$SetEntriesTableAnnotationComposer a) f,
  ) {
    final $$SetEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setEntries,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.setEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutSessionsTable,
          WorkoutSession,
          $$WorkoutSessionsTableFilterComposer,
          $$WorkoutSessionsTableOrderingComposer,
          $$WorkoutSessionsTableAnnotationComposer,
          $$WorkoutSessionsTableCreateCompanionBuilder,
          $$WorkoutSessionsTableUpdateCompanionBuilder,
          (WorkoutSession, $$WorkoutSessionsTableReferences),
          WorkoutSession,
          PrefetchHooks Function({bool setEntriesRefs})
        > {
  $$WorkoutSessionsTableTableManager(
    _$AppDatabase db,
    $WorkoutSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int?> dayId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int?> durationSec = const Value.absent(),
                Value<int?> perceivedEffort = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => WorkoutSessionsCompanion(
                id: id,
                date: date,
                dayId: dayId,
                name: name,
                startedAt: startedAt,
                completedAt: completedAt,
                durationSec: durationSec,
                perceivedEffort: perceivedEffort,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String date,
                Value<int?> dayId = const Value.absent(),
                required String name,
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int?> durationSec = const Value.absent(),
                Value<int?> perceivedEffort = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => WorkoutSessionsCompanion.insert(
                id: id,
                date: date,
                dayId: dayId,
                name: name,
                startedAt: startedAt,
                completedAt: completedAt,
                durationSec: durationSec,
                perceivedEffort: perceivedEffort,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WorkoutSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({setEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (setEntriesRefs) db.setEntries],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (setEntriesRefs)
                    await $_getPrefetchedData<
                      WorkoutSession,
                      $WorkoutSessionsTable,
                      SetEntry
                    >(
                      currentTable: table,
                      referencedTable: $$WorkoutSessionsTableReferences
                          ._setEntriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$WorkoutSessionsTableReferences(
                            db,
                            table,
                            p0,
                          ).setEntriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sessionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$WorkoutSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutSessionsTable,
      WorkoutSession,
      $$WorkoutSessionsTableFilterComposer,
      $$WorkoutSessionsTableOrderingComposer,
      $$WorkoutSessionsTableAnnotationComposer,
      $$WorkoutSessionsTableCreateCompanionBuilder,
      $$WorkoutSessionsTableUpdateCompanionBuilder,
      (WorkoutSession, $$WorkoutSessionsTableReferences),
      WorkoutSession,
      PrefetchHooks Function({bool setEntriesRefs})
    >;
typedef $$SetEntriesTableCreateCompanionBuilder =
    SetEntriesCompanion Function({
      Value<int> id,
      required int sessionId,
      required int exerciseId,
      required int position,
      required int setIndex,
      Value<int?> reps,
      Value<double?> weightKg,
      Value<int?> durationSec,
      Value<double?> distanceM,
      Value<double?> rpe,
      Value<String?> enteredUnit,
      Value<bool> isWarmup,
      Value<bool> completed,
      Value<DateTime> createdAt,
    });
typedef $$SetEntriesTableUpdateCompanionBuilder =
    SetEntriesCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<int> exerciseId,
      Value<int> position,
      Value<int> setIndex,
      Value<int?> reps,
      Value<double?> weightKg,
      Value<int?> durationSec,
      Value<double?> distanceM,
      Value<double?> rpe,
      Value<String?> enteredUnit,
      Value<bool> isWarmup,
      Value<bool> completed,
      Value<DateTime> createdAt,
    });

final class $$SetEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $SetEntriesTable, SetEntry> {
  $$SetEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutSessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.workoutSessions.createAlias(
        $_aliasNameGenerator(db.setEntries.sessionId, db.workoutSessions.id),
      );

  $$WorkoutSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$WorkoutSessionsTableTableManager(
      $_db,
      $_db.workoutSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias(
        $_aliasNameGenerator(db.setEntries.exerciseId, db.exercises.id),
      );

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<int>('exercise_id')!;

    final manager = $$ExercisesTableTableManager(
      $_db,
      $_db.exercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SetEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SetEntriesTable> {
  $$SetEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rpe => $composableBuilder(
    column: $table.rpe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enteredUnit => $composableBuilder(
    column: $table.enteredUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isWarmup => $composableBuilder(
    column: $table.isWarmup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkoutSessionsTableFilterComposer get sessionId {
    final $$WorkoutSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSessionsTableFilterComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SetEntriesTable> {
  $$SetEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rpe => $composableBuilder(
    column: $table.rpe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enteredUnit => $composableBuilder(
    column: $table.enteredUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isWarmup => $composableBuilder(
    column: $table.isWarmup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkoutSessionsTableOrderingComposer get sessionId {
    final $$WorkoutSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SetEntriesTable> {
  $$SetEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get setIndex =>
      $composableBuilder(column: $table.setIndex, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => column);

  GeneratedColumn<double> get rpe =>
      $composableBuilder(column: $table.rpe, builder: (column) => column);

  GeneratedColumn<String> get enteredUnit => $composableBuilder(
    column: $table.enteredUnit,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isWarmup =>
      $composableBuilder(column: $table.isWarmup, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$WorkoutSessionsTableAnnotationComposer get sessionId {
    final $$WorkoutSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SetEntriesTable,
          SetEntry,
          $$SetEntriesTableFilterComposer,
          $$SetEntriesTableOrderingComposer,
          $$SetEntriesTableAnnotationComposer,
          $$SetEntriesTableCreateCompanionBuilder,
          $$SetEntriesTableUpdateCompanionBuilder,
          (SetEntry, $$SetEntriesTableReferences),
          SetEntry,
          PrefetchHooks Function({bool sessionId, bool exerciseId})
        > {
  $$SetEntriesTableTableManager(_$AppDatabase db, $SetEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SetEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SetEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SetEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<int> exerciseId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> setIndex = const Value.absent(),
                Value<int?> reps = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<int?> durationSec = const Value.absent(),
                Value<double?> distanceM = const Value.absent(),
                Value<double?> rpe = const Value.absent(),
                Value<String?> enteredUnit = const Value.absent(),
                Value<bool> isWarmup = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SetEntriesCompanion(
                id: id,
                sessionId: sessionId,
                exerciseId: exerciseId,
                position: position,
                setIndex: setIndex,
                reps: reps,
                weightKg: weightKg,
                durationSec: durationSec,
                distanceM: distanceM,
                rpe: rpe,
                enteredUnit: enteredUnit,
                isWarmup: isWarmup,
                completed: completed,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required int exerciseId,
                required int position,
                required int setIndex,
                Value<int?> reps = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<int?> durationSec = const Value.absent(),
                Value<double?> distanceM = const Value.absent(),
                Value<double?> rpe = const Value.absent(),
                Value<String?> enteredUnit = const Value.absent(),
                Value<bool> isWarmup = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SetEntriesCompanion.insert(
                id: id,
                sessionId: sessionId,
                exerciseId: exerciseId,
                position: position,
                setIndex: setIndex,
                reps: reps,
                weightKg: weightKg,
                durationSec: durationSec,
                distanceM: distanceM,
                rpe: rpe,
                enteredUnit: enteredUnit,
                isWarmup: isWarmup,
                completed: completed,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SetEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false, exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$SetEntriesTableReferences
                                    ._sessionIdTable(db),
                                referencedColumn: $$SetEntriesTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (exerciseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.exerciseId,
                                referencedTable: $$SetEntriesTableReferences
                                    ._exerciseIdTable(db),
                                referencedColumn: $$SetEntriesTableReferences
                                    ._exerciseIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SetEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SetEntriesTable,
      SetEntry,
      $$SetEntriesTableFilterComposer,
      $$SetEntriesTableOrderingComposer,
      $$SetEntriesTableAnnotationComposer,
      $$SetEntriesTableCreateCompanionBuilder,
      $$SetEntriesTableUpdateCompanionBuilder,
      (SetEntry, $$SetEntriesTableReferences),
      SetEntry,
      PrefetchHooks Function({bool sessionId, bool exerciseId})
    >;
typedef $$WorkoutTemplatesTableCreateCompanionBuilder =
    WorkoutTemplatesCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> notes,
      Value<int> position,
      Value<DateTime> createdAt,
    });
typedef $$WorkoutTemplatesTableUpdateCompanionBuilder =
    WorkoutTemplatesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> notes,
      Value<int> position,
      Value<DateTime> createdAt,
    });

final class $$WorkoutTemplatesTableReferences
    extends
        BaseReferences<_$AppDatabase, $WorkoutTemplatesTable, WorkoutTemplate> {
  $$WorkoutTemplatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$TemplateDaysTable, List<TemplateDay>>
  _templateDaysRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.templateDays,
    aliasName: $_aliasNameGenerator(
      db.workoutTemplates.id,
      db.templateDays.templateId,
    ),
  );

  $$TemplateDaysTableProcessedTableManager get templateDaysRefs {
    final manager = $$TemplateDaysTableTableManager(
      $_db,
      $_db.templateDays,
    ).filter((f) => f.templateId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_templateDaysRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkoutTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutTemplatesTable> {
  $$WorkoutTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> templateDaysRefs(
    Expression<bool> Function($$TemplateDaysTableFilterComposer f) f,
  ) {
    final $$TemplateDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateDays,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateDaysTableFilterComposer(
            $db: $db,
            $table: $db.templateDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutTemplatesTable> {
  $$WorkoutTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkoutTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutTemplatesTable> {
  $$WorkoutTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> templateDaysRefs<T extends Object>(
    Expression<T> Function($$TemplateDaysTableAnnotationComposer a) f,
  ) {
    final $$TemplateDaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateDays,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateDaysTableAnnotationComposer(
            $db: $db,
            $table: $db.templateDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutTemplatesTable,
          WorkoutTemplate,
          $$WorkoutTemplatesTableFilterComposer,
          $$WorkoutTemplatesTableOrderingComposer,
          $$WorkoutTemplatesTableAnnotationComposer,
          $$WorkoutTemplatesTableCreateCompanionBuilder,
          $$WorkoutTemplatesTableUpdateCompanionBuilder,
          (WorkoutTemplate, $$WorkoutTemplatesTableReferences),
          WorkoutTemplate,
          PrefetchHooks Function({bool templateDaysRefs})
        > {
  $$WorkoutTemplatesTableTableManager(
    _$AppDatabase db,
    $WorkoutTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => WorkoutTemplatesCompanion(
                id: id,
                name: name,
                notes: notes,
                position: position,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> notes = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => WorkoutTemplatesCompanion.insert(
                id: id,
                name: name,
                notes: notes,
                position: position,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WorkoutTemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({templateDaysRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (templateDaysRefs) db.templateDays],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (templateDaysRefs)
                    await $_getPrefetchedData<
                      WorkoutTemplate,
                      $WorkoutTemplatesTable,
                      TemplateDay
                    >(
                      currentTable: table,
                      referencedTable: $$WorkoutTemplatesTableReferences
                          ._templateDaysRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$WorkoutTemplatesTableReferences(
                            db,
                            table,
                            p0,
                          ).templateDaysRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.templateId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$WorkoutTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutTemplatesTable,
      WorkoutTemplate,
      $$WorkoutTemplatesTableFilterComposer,
      $$WorkoutTemplatesTableOrderingComposer,
      $$WorkoutTemplatesTableAnnotationComposer,
      $$WorkoutTemplatesTableCreateCompanionBuilder,
      $$WorkoutTemplatesTableUpdateCompanionBuilder,
      (WorkoutTemplate, $$WorkoutTemplatesTableReferences),
      WorkoutTemplate,
      PrefetchHooks Function({bool templateDaysRefs})
    >;
typedef $$TemplateDaysTableCreateCompanionBuilder =
    TemplateDaysCompanion Function({
      Value<int> id,
      required int templateId,
      required String name,
      Value<int> position,
      Value<String?> notes,
      Value<DateTime> createdAt,
    });
typedef $$TemplateDaysTableUpdateCompanionBuilder =
    TemplateDaysCompanion Function({
      Value<int> id,
      Value<int> templateId,
      Value<String> name,
      Value<int> position,
      Value<String?> notes,
      Value<DateTime> createdAt,
    });

final class $$TemplateDaysTableReferences
    extends BaseReferences<_$AppDatabase, $TemplateDaysTable, TemplateDay> {
  $$TemplateDaysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutTemplatesTable _templateIdTable(_$AppDatabase db) =>
      db.workoutTemplates.createAlias(
        $_aliasNameGenerator(
          db.templateDays.templateId,
          db.workoutTemplates.id,
        ),
      );

  $$WorkoutTemplatesTableProcessedTableManager get templateId {
    final $_column = $_itemColumn<int>('template_id')!;

    final manager = $$WorkoutTemplatesTableTableManager(
      $_db,
      $_db.workoutTemplates,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TemplateExercisesTable, List<TemplateExercise>>
  _templateExercisesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.templateExercises,
        aliasName: $_aliasNameGenerator(
          db.templateDays.id,
          db.templateExercises.dayId,
        ),
      );

  $$TemplateExercisesTableProcessedTableManager get templateExercisesRefs {
    final manager = $$TemplateExercisesTableTableManager(
      $_db,
      $_db.templateExercises,
    ).filter((f) => f.dayId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _templateExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ScheduleEntriesTable, List<ScheduleEntry>>
  _scheduleEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.scheduleEntries,
    aliasName: $_aliasNameGenerator(
      db.templateDays.id,
      db.scheduleEntries.dayId,
    ),
  );

  $$ScheduleEntriesTableProcessedTableManager get scheduleEntriesRefs {
    final manager = $$ScheduleEntriesTableTableManager(
      $_db,
      $_db.scheduleEntries,
    ).filter((f) => f.dayId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _scheduleEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TemplateDaysTableFilterComposer
    extends Composer<_$AppDatabase, $TemplateDaysTable> {
  $$TemplateDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkoutTemplatesTableFilterComposer get templateId {
    final $$WorkoutTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.workoutTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.workoutTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> templateExercisesRefs(
    Expression<bool> Function($$TemplateExercisesTableFilterComposer f) f,
  ) {
    final $$TemplateExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateExercises,
      getReferencedColumn: (t) => t.dayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateExercisesTableFilterComposer(
            $db: $db,
            $table: $db.templateExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> scheduleEntriesRefs(
    Expression<bool> Function($$ScheduleEntriesTableFilterComposer f) f,
  ) {
    final $$ScheduleEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scheduleEntries,
      getReferencedColumn: (t) => t.dayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScheduleEntriesTableFilterComposer(
            $db: $db,
            $table: $db.scheduleEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TemplateDaysTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplateDaysTable> {
  $$TemplateDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkoutTemplatesTableOrderingComposer get templateId {
    final $$WorkoutTemplatesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.workoutTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutTemplatesTableOrderingComposer(
            $db: $db,
            $table: $db.workoutTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TemplateDaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplateDaysTable> {
  $$TemplateDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$WorkoutTemplatesTableAnnotationComposer get templateId {
    final $$WorkoutTemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.workoutTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutTemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> templateExercisesRefs<T extends Object>(
    Expression<T> Function($$TemplateExercisesTableAnnotationComposer a) f,
  ) {
    final $$TemplateExercisesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.templateExercises,
          getReferencedColumn: (t) => t.dayId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TemplateExercisesTableAnnotationComposer(
                $db: $db,
                $table: $db.templateExercises,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> scheduleEntriesRefs<T extends Object>(
    Expression<T> Function($$ScheduleEntriesTableAnnotationComposer a) f,
  ) {
    final $$ScheduleEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scheduleEntries,
      getReferencedColumn: (t) => t.dayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScheduleEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.scheduleEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TemplateDaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TemplateDaysTable,
          TemplateDay,
          $$TemplateDaysTableFilterComposer,
          $$TemplateDaysTableOrderingComposer,
          $$TemplateDaysTableAnnotationComposer,
          $$TemplateDaysTableCreateCompanionBuilder,
          $$TemplateDaysTableUpdateCompanionBuilder,
          (TemplateDay, $$TemplateDaysTableReferences),
          TemplateDay,
          PrefetchHooks Function({
            bool templateId,
            bool templateExercisesRefs,
            bool scheduleEntriesRefs,
          })
        > {
  $$TemplateDaysTableTableManager(_$AppDatabase db, $TemplateDaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplateDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplateDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplateDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> templateId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TemplateDaysCompanion(
                id: id,
                templateId: templateId,
                name: name,
                position: position,
                notes: notes,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int templateId,
                required String name,
                Value<int> position = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TemplateDaysCompanion.insert(
                id: id,
                templateId: templateId,
                name: name,
                position: position,
                notes: notes,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TemplateDaysTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                templateId = false,
                templateExercisesRefs = false,
                scheduleEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (templateExercisesRefs) db.templateExercises,
                    if (scheduleEntriesRefs) db.scheduleEntries,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (templateId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.templateId,
                                    referencedTable:
                                        $$TemplateDaysTableReferences
                                            ._templateIdTable(db),
                                    referencedColumn:
                                        $$TemplateDaysTableReferences
                                            ._templateIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (templateExercisesRefs)
                        await $_getPrefetchedData<
                          TemplateDay,
                          $TemplateDaysTable,
                          TemplateExercise
                        >(
                          currentTable: table,
                          referencedTable: $$TemplateDaysTableReferences
                              ._templateExercisesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TemplateDaysTableReferences(
                                db,
                                table,
                                p0,
                              ).templateExercisesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.dayId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (scheduleEntriesRefs)
                        await $_getPrefetchedData<
                          TemplateDay,
                          $TemplateDaysTable,
                          ScheduleEntry
                        >(
                          currentTable: table,
                          referencedTable: $$TemplateDaysTableReferences
                              ._scheduleEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TemplateDaysTableReferences(
                                db,
                                table,
                                p0,
                              ).scheduleEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.dayId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TemplateDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TemplateDaysTable,
      TemplateDay,
      $$TemplateDaysTableFilterComposer,
      $$TemplateDaysTableOrderingComposer,
      $$TemplateDaysTableAnnotationComposer,
      $$TemplateDaysTableCreateCompanionBuilder,
      $$TemplateDaysTableUpdateCompanionBuilder,
      (TemplateDay, $$TemplateDaysTableReferences),
      TemplateDay,
      PrefetchHooks Function({
        bool templateId,
        bool templateExercisesRefs,
        bool scheduleEntriesRefs,
      })
    >;
typedef $$TemplateExercisesTableCreateCompanionBuilder =
    TemplateExercisesCompanion Function({
      Value<int> id,
      required int dayId,
      required int exerciseId,
      required int position,
      Value<int?> targetSets,
      Value<String?> targetReps,
      Value<double?> targetWeightKg,
      Value<int?> targetDurationSec,
      Value<double?> targetDistanceM,
      Value<String?> notes,
    });
typedef $$TemplateExercisesTableUpdateCompanionBuilder =
    TemplateExercisesCompanion Function({
      Value<int> id,
      Value<int> dayId,
      Value<int> exerciseId,
      Value<int> position,
      Value<int?> targetSets,
      Value<String?> targetReps,
      Value<double?> targetWeightKg,
      Value<int?> targetDurationSec,
      Value<double?> targetDistanceM,
      Value<String?> notes,
    });

final class $$TemplateExercisesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TemplateExercisesTable,
          TemplateExercise
        > {
  $$TemplateExercisesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TemplateDaysTable _dayIdTable(_$AppDatabase db) =>
      db.templateDays.createAlias(
        $_aliasNameGenerator(db.templateExercises.dayId, db.templateDays.id),
      );

  $$TemplateDaysTableProcessedTableManager get dayId {
    final $_column = $_itemColumn<int>('day_id')!;

    final manager = $$TemplateDaysTableTableManager(
      $_db,
      $_db.templateDays,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dayIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias(
        $_aliasNameGenerator(db.templateExercises.exerciseId, db.exercises.id),
      );

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<int>('exercise_id')!;

    final manager = $$ExercisesTableTableManager(
      $_db,
      $_db.exercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TemplateExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $TemplateExercisesTable> {
  $$TemplateExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetSets => $composableBuilder(
    column: $table.targetSets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetWeightKg => $composableBuilder(
    column: $table.targetWeightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetDurationSec => $composableBuilder(
    column: $table.targetDurationSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetDistanceM => $composableBuilder(
    column: $table.targetDistanceM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $$TemplateDaysTableFilterComposer get dayId {
    final $$TemplateDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayId,
      referencedTable: $db.templateDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateDaysTableFilterComposer(
            $db: $db,
            $table: $db.templateDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TemplateExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplateExercisesTable> {
  $$TemplateExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetSets => $composableBuilder(
    column: $table.targetSets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetWeightKg => $composableBuilder(
    column: $table.targetWeightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetDurationSec => $composableBuilder(
    column: $table.targetDurationSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetDistanceM => $composableBuilder(
    column: $table.targetDistanceM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $$TemplateDaysTableOrderingComposer get dayId {
    final $$TemplateDaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayId,
      referencedTable: $db.templateDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateDaysTableOrderingComposer(
            $db: $db,
            $table: $db.templateDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TemplateExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplateExercisesTable> {
  $$TemplateExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get targetSets => $composableBuilder(
    column: $table.targetSets,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetWeightKg => $composableBuilder(
    column: $table.targetWeightKg,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetDurationSec => $composableBuilder(
    column: $table.targetDurationSec,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetDistanceM => $composableBuilder(
    column: $table.targetDistanceM,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$TemplateDaysTableAnnotationComposer get dayId {
    final $$TemplateDaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayId,
      referencedTable: $db.templateDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateDaysTableAnnotationComposer(
            $db: $db,
            $table: $db.templateDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TemplateExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TemplateExercisesTable,
          TemplateExercise,
          $$TemplateExercisesTableFilterComposer,
          $$TemplateExercisesTableOrderingComposer,
          $$TemplateExercisesTableAnnotationComposer,
          $$TemplateExercisesTableCreateCompanionBuilder,
          $$TemplateExercisesTableUpdateCompanionBuilder,
          (TemplateExercise, $$TemplateExercisesTableReferences),
          TemplateExercise,
          PrefetchHooks Function({bool dayId, bool exerciseId})
        > {
  $$TemplateExercisesTableTableManager(
    _$AppDatabase db,
    $TemplateExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplateExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplateExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplateExercisesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dayId = const Value.absent(),
                Value<int> exerciseId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int?> targetSets = const Value.absent(),
                Value<String?> targetReps = const Value.absent(),
                Value<double?> targetWeightKg = const Value.absent(),
                Value<int?> targetDurationSec = const Value.absent(),
                Value<double?> targetDistanceM = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => TemplateExercisesCompanion(
                id: id,
                dayId: dayId,
                exerciseId: exerciseId,
                position: position,
                targetSets: targetSets,
                targetReps: targetReps,
                targetWeightKg: targetWeightKg,
                targetDurationSec: targetDurationSec,
                targetDistanceM: targetDistanceM,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int dayId,
                required int exerciseId,
                required int position,
                Value<int?> targetSets = const Value.absent(),
                Value<String?> targetReps = const Value.absent(),
                Value<double?> targetWeightKg = const Value.absent(),
                Value<int?> targetDurationSec = const Value.absent(),
                Value<double?> targetDistanceM = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => TemplateExercisesCompanion.insert(
                id: id,
                dayId: dayId,
                exerciseId: exerciseId,
                position: position,
                targetSets: targetSets,
                targetReps: targetReps,
                targetWeightKg: targetWeightKg,
                targetDurationSec: targetDurationSec,
                targetDistanceM: targetDistanceM,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TemplateExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({dayId = false, exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (dayId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.dayId,
                                referencedTable:
                                    $$TemplateExercisesTableReferences
                                        ._dayIdTable(db),
                                referencedColumn:
                                    $$TemplateExercisesTableReferences
                                        ._dayIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (exerciseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.exerciseId,
                                referencedTable:
                                    $$TemplateExercisesTableReferences
                                        ._exerciseIdTable(db),
                                referencedColumn:
                                    $$TemplateExercisesTableReferences
                                        ._exerciseIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TemplateExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TemplateExercisesTable,
      TemplateExercise,
      $$TemplateExercisesTableFilterComposer,
      $$TemplateExercisesTableOrderingComposer,
      $$TemplateExercisesTableAnnotationComposer,
      $$TemplateExercisesTableCreateCompanionBuilder,
      $$TemplateExercisesTableUpdateCompanionBuilder,
      (TemplateExercise, $$TemplateExercisesTableReferences),
      TemplateExercise,
      PrefetchHooks Function({bool dayId, bool exerciseId})
    >;
typedef $$ScheduleEntriesTableCreateCompanionBuilder =
    ScheduleEntriesCompanion Function({
      Value<int> id,
      required int dayOfWeek,
      required int dayId,
      Value<int> position,
    });
typedef $$ScheduleEntriesTableUpdateCompanionBuilder =
    ScheduleEntriesCompanion Function({
      Value<int> id,
      Value<int> dayOfWeek,
      Value<int> dayId,
      Value<int> position,
    });

final class $$ScheduleEntriesTableReferences
    extends
        BaseReferences<_$AppDatabase, $ScheduleEntriesTable, ScheduleEntry> {
  $$ScheduleEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TemplateDaysTable _dayIdTable(_$AppDatabase db) =>
      db.templateDays.createAlias(
        $_aliasNameGenerator(db.scheduleEntries.dayId, db.templateDays.id),
      );

  $$TemplateDaysTableProcessedTableManager get dayId {
    final $_column = $_itemColumn<int>('day_id')!;

    final manager = $$TemplateDaysTableTableManager(
      $_db,
      $_db.templateDays,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dayIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ScheduleEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $ScheduleEntriesTable> {
  $$ScheduleEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$TemplateDaysTableFilterComposer get dayId {
    final $$TemplateDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayId,
      referencedTable: $db.templateDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateDaysTableFilterComposer(
            $db: $db,
            $table: $db.templateDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScheduleEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ScheduleEntriesTable> {
  $$ScheduleEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$TemplateDaysTableOrderingComposer get dayId {
    final $$TemplateDaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayId,
      referencedTable: $db.templateDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateDaysTableOrderingComposer(
            $db: $db,
            $table: $db.templateDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScheduleEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScheduleEntriesTable> {
  $$ScheduleEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dayOfWeek =>
      $composableBuilder(column: $table.dayOfWeek, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$TemplateDaysTableAnnotationComposer get dayId {
    final $$TemplateDaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayId,
      referencedTable: $db.templateDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateDaysTableAnnotationComposer(
            $db: $db,
            $table: $db.templateDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScheduleEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScheduleEntriesTable,
          ScheduleEntry,
          $$ScheduleEntriesTableFilterComposer,
          $$ScheduleEntriesTableOrderingComposer,
          $$ScheduleEntriesTableAnnotationComposer,
          $$ScheduleEntriesTableCreateCompanionBuilder,
          $$ScheduleEntriesTableUpdateCompanionBuilder,
          (ScheduleEntry, $$ScheduleEntriesTableReferences),
          ScheduleEntry,
          PrefetchHooks Function({bool dayId})
        > {
  $$ScheduleEntriesTableTableManager(
    _$AppDatabase db,
    $ScheduleEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScheduleEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScheduleEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScheduleEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dayOfWeek = const Value.absent(),
                Value<int> dayId = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) => ScheduleEntriesCompanion(
                id: id,
                dayOfWeek: dayOfWeek,
                dayId: dayId,
                position: position,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int dayOfWeek,
                required int dayId,
                Value<int> position = const Value.absent(),
              }) => ScheduleEntriesCompanion.insert(
                id: id,
                dayOfWeek: dayOfWeek,
                dayId: dayId,
                position: position,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ScheduleEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({dayId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (dayId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.dayId,
                                referencedTable:
                                    $$ScheduleEntriesTableReferences
                                        ._dayIdTable(db),
                                referencedColumn:
                                    $$ScheduleEntriesTableReferences
                                        ._dayIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ScheduleEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScheduleEntriesTable,
      ScheduleEntry,
      $$ScheduleEntriesTableFilterComposer,
      $$ScheduleEntriesTableOrderingComposer,
      $$ScheduleEntriesTableAnnotationComposer,
      $$ScheduleEntriesTableCreateCompanionBuilder,
      $$ScheduleEntriesTableUpdateCompanionBuilder,
      (ScheduleEntry, $$ScheduleEntriesTableReferences),
      ScheduleEntry,
      PrefetchHooks Function({bool dayId})
    >;
typedef $$DailyActivityTableCreateCompanionBuilder =
    DailyActivityCompanion Function({
      required String date,
      Value<int?> steps,
      Value<int?> activeMinutes,
      Value<String> source,
      Value<int> rowid,
    });
typedef $$DailyActivityTableUpdateCompanionBuilder =
    DailyActivityCompanion Function({
      Value<String> date,
      Value<int?> steps,
      Value<int?> activeMinutes,
      Value<String> source,
      Value<int> rowid,
    });

class $$DailyActivityTableFilterComposer
    extends Composer<_$AppDatabase, $DailyActivityTable> {
  $$DailyActivityTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activeMinutes => $composableBuilder(
    column: $table.activeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyActivityTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyActivityTable> {
  $$DailyActivityTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activeMinutes => $composableBuilder(
    column: $table.activeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyActivityTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyActivityTable> {
  $$DailyActivityTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get steps =>
      $composableBuilder(column: $table.steps, builder: (column) => column);

  GeneratedColumn<int> get activeMinutes => $composableBuilder(
    column: $table.activeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$DailyActivityTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyActivityTable,
          DailyActivityData,
          $$DailyActivityTableFilterComposer,
          $$DailyActivityTableOrderingComposer,
          $$DailyActivityTableAnnotationComposer,
          $$DailyActivityTableCreateCompanionBuilder,
          $$DailyActivityTableUpdateCompanionBuilder,
          (
            DailyActivityData,
            BaseReferences<
              _$AppDatabase,
              $DailyActivityTable,
              DailyActivityData
            >,
          ),
          DailyActivityData,
          PrefetchHooks Function()
        > {
  $$DailyActivityTableTableManager(_$AppDatabase db, $DailyActivityTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyActivityTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyActivityTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyActivityTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<int?> steps = const Value.absent(),
                Value<int?> activeMinutes = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyActivityCompanion(
                date: date,
                steps: steps,
                activeMinutes: activeMinutes,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                Value<int?> steps = const Value.absent(),
                Value<int?> activeMinutes = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyActivityCompanion.insert(
                date: date,
                steps: steps,
                activeMinutes: activeMinutes,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyActivityTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyActivityTable,
      DailyActivityData,
      $$DailyActivityTableFilterComposer,
      $$DailyActivityTableOrderingComposer,
      $$DailyActivityTableAnnotationComposer,
      $$DailyActivityTableCreateCompanionBuilder,
      $$DailyActivityTableUpdateCompanionBuilder,
      (
        DailyActivityData,
        BaseReferences<_$AppDatabase, $DailyActivityTable, DailyActivityData>,
      ),
      DailyActivityData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RecipesTableTableManager get recipes =>
      $$RecipesTableTableManager(_db, _db.recipes);
  $$RecipeIngredientsTableTableManager get recipeIngredients =>
      $$RecipeIngredientsTableTableManager(_db, _db.recipeIngredients);
  $$RecipeStepsTableTableManager get recipeSteps =>
      $$RecipeStepsTableTableManager(_db, _db.recipeSteps);
  $$RecipeNutritionCacheTableTableManager get recipeNutritionCache =>
      $$RecipeNutritionCacheTableTableManager(_db, _db.recipeNutritionCache);
  $$FoodCacheTableTableManager get foodCache =>
      $$FoodCacheTableTableManager(_db, _db.foodCache);
  $$FoodUnitWeightsTableTableManager get foodUnitWeights =>
      $$FoodUnitWeightsTableTableManager(_db, _db.foodUnitWeights);
  $$LogEntriesTableTableManager get logEntries =>
      $$LogEntriesTableTableManager(_db, _db.logEntries);
  $$DailyTargetsTableTableTableManager get dailyTargetsTable =>
      $$DailyTargetsTableTableTableManager(_db, _db.dailyTargetsTable);
  $$AdaptiveTargetsTableTableManager get adaptiveTargets =>
      $$AdaptiveTargetsTableTableManager(_db, _db.adaptiveTargets);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$GroceryItemsTableTableManager get groceryItems =>
      $$GroceryItemsTableTableManager(_db, _db.groceryItems);
  $$WeightEntriesTableTableManager get weightEntries =>
      $$WeightEntriesTableTableManager(_db, _db.weightEntries);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$WorkoutSessionsTableTableManager get workoutSessions =>
      $$WorkoutSessionsTableTableManager(_db, _db.workoutSessions);
  $$SetEntriesTableTableManager get setEntries =>
      $$SetEntriesTableTableManager(_db, _db.setEntries);
  $$WorkoutTemplatesTableTableManager get workoutTemplates =>
      $$WorkoutTemplatesTableTableManager(_db, _db.workoutTemplates);
  $$TemplateDaysTableTableManager get templateDays =>
      $$TemplateDaysTableTableManager(_db, _db.templateDays);
  $$TemplateExercisesTableTableManager get templateExercises =>
      $$TemplateExercisesTableTableManager(_db, _db.templateExercises);
  $$ScheduleEntriesTableTableManager get scheduleEntries =>
      $$ScheduleEntriesTableTableManager(_db, _db.scheduleEntries);
  $$DailyActivityTableTableManager get dailyActivity =>
      $$DailyActivityTableTableManager(_db, _db.dailyActivity);
}
