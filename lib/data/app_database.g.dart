// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, Reminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
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
    requiredDuringInsert: false,
    defaultValue: const Constant('喝水提醒'),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('该喝水啦 💧'),
  );
  static const VerificationMeta _repeatTypeMeta = const VerificationMeta(
    'repeatType',
  );
  @override
  late final GeneratedColumn<int> repeatType = GeneratedColumn<int>(
    'repeat_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hourMeta = const VerificationMeta('hour');
  @override
  late final GeneratedColumn<int> hour = GeneratedColumn<int>(
    'hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minuteMeta = const VerificationMeta('minute');
  @override
  late final GeneratedColumn<int> minute = GeneratedColumn<int>(
    'minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weekdaysMeta = const VerificationMeta(
    'weekdays',
  );
  @override
  late final GeneratedColumn<String> weekdays = GeneratedColumn<String>(
    'weekdays',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _monthDayMeta = const VerificationMeta(
    'monthDay',
  );
  @override
  late final GeneratedColumn<int> monthDay = GeneratedColumn<int>(
    'month_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _triggerAtMeta = const VerificationMeta(
    'triggerAt',
  );
  @override
  late final GeneratedColumn<int> triggerAt = GeneratedColumn<int>(
    'trigger_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    body,
    repeatType,
    hour,
    minute,
    weekdays,
    monthDay,
    triggerAt,
    enabled,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reminder> instance, {
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
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('repeat_type')) {
      context.handle(
        _repeatTypeMeta,
        repeatType.isAcceptableOrUnknown(data['repeat_type']!, _repeatTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_repeatTypeMeta);
    }
    if (data.containsKey('hour')) {
      context.handle(
        _hourMeta,
        hour.isAcceptableOrUnknown(data['hour']!, _hourMeta),
      );
    } else if (isInserting) {
      context.missing(_hourMeta);
    }
    if (data.containsKey('minute')) {
      context.handle(
        _minuteMeta,
        minute.isAcceptableOrUnknown(data['minute']!, _minuteMeta),
      );
    } else if (isInserting) {
      context.missing(_minuteMeta);
    }
    if (data.containsKey('weekdays')) {
      context.handle(
        _weekdaysMeta,
        weekdays.isAcceptableOrUnknown(data['weekdays']!, _weekdaysMeta),
      );
    }
    if (data.containsKey('month_day')) {
      context.handle(
        _monthDayMeta,
        monthDay.isAcceptableOrUnknown(data['month_day']!, _monthDayMeta),
      );
    }
    if (data.containsKey('trigger_at')) {
      context.handle(
        _triggerAtMeta,
        triggerAt.isAcceptableOrUnknown(data['trigger_at']!, _triggerAtMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reminder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      repeatType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repeat_type'],
      )!,
      hour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hour'],
      )!,
      minute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minute'],
      )!,
      weekdays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weekdays'],
      )!,
      monthDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month_day'],
      ),
      triggerAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trigger_at'],
      ),
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class Reminder extends DataClass implements Insertable<Reminder> {
  final int id;
  final String title;
  final String body;
  final int repeatType;
  final int hour;
  final int minute;
  final String weekdays;
  final int? monthDay;
  final int? triggerAt;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Reminder({
    required this.id,
    required this.title,
    required this.body,
    required this.repeatType,
    required this.hour,
    required this.minute,
    required this.weekdays,
    this.monthDay,
    this.triggerAt,
    required this.enabled,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['repeat_type'] = Variable<int>(repeatType);
    map['hour'] = Variable<int>(hour);
    map['minute'] = Variable<int>(minute);
    map['weekdays'] = Variable<String>(weekdays);
    if (!nullToAbsent || monthDay != null) {
      map['month_day'] = Variable<int>(monthDay);
    }
    if (!nullToAbsent || triggerAt != null) {
      map['trigger_at'] = Variable<int>(triggerAt);
    }
    map['enabled'] = Variable<bool>(enabled);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      title: Value(title),
      body: Value(body),
      repeatType: Value(repeatType),
      hour: Value(hour),
      minute: Value(minute),
      weekdays: Value(weekdays),
      monthDay: monthDay == null && nullToAbsent
          ? const Value.absent()
          : Value(monthDay),
      triggerAt: triggerAt == null && nullToAbsent
          ? const Value.absent()
          : Value(triggerAt),
      enabled: Value(enabled),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Reminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reminder(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      repeatType: serializer.fromJson<int>(json['repeatType']),
      hour: serializer.fromJson<int>(json['hour']),
      minute: serializer.fromJson<int>(json['minute']),
      weekdays: serializer.fromJson<String>(json['weekdays']),
      monthDay: serializer.fromJson<int?>(json['monthDay']),
      triggerAt: serializer.fromJson<int?>(json['triggerAt']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'repeatType': serializer.toJson<int>(repeatType),
      'hour': serializer.toJson<int>(hour),
      'minute': serializer.toJson<int>(minute),
      'weekdays': serializer.toJson<String>(weekdays),
      'monthDay': serializer.toJson<int?>(monthDay),
      'triggerAt': serializer.toJson<int?>(triggerAt),
      'enabled': serializer.toJson<bool>(enabled),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Reminder copyWith({
    int? id,
    String? title,
    String? body,
    int? repeatType,
    int? hour,
    int? minute,
    String? weekdays,
    Value<int?> monthDay = const Value.absent(),
    Value<int?> triggerAt = const Value.absent(),
    bool? enabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Reminder(
    id: id ?? this.id,
    title: title ?? this.title,
    body: body ?? this.body,
    repeatType: repeatType ?? this.repeatType,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    weekdays: weekdays ?? this.weekdays,
    monthDay: monthDay.present ? monthDay.value : this.monthDay,
    triggerAt: triggerAt.present ? triggerAt.value : this.triggerAt,
    enabled: enabled ?? this.enabled,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Reminder copyWithCompanion(RemindersCompanion data) {
    return Reminder(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      repeatType: data.repeatType.present
          ? data.repeatType.value
          : this.repeatType,
      hour: data.hour.present ? data.hour.value : this.hour,
      minute: data.minute.present ? data.minute.value : this.minute,
      weekdays: data.weekdays.present ? data.weekdays.value : this.weekdays,
      monthDay: data.monthDay.present ? data.monthDay.value : this.monthDay,
      triggerAt: data.triggerAt.present ? data.triggerAt.value : this.triggerAt,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reminder(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('repeatType: $repeatType, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('weekdays: $weekdays, ')
          ..write('monthDay: $monthDay, ')
          ..write('triggerAt: $triggerAt, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    body,
    repeatType,
    hour,
    minute,
    weekdays,
    monthDay,
    triggerAt,
    enabled,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reminder &&
          other.id == this.id &&
          other.title == this.title &&
          other.body == this.body &&
          other.repeatType == this.repeatType &&
          other.hour == this.hour &&
          other.minute == this.minute &&
          other.weekdays == this.weekdays &&
          other.monthDay == this.monthDay &&
          other.triggerAt == this.triggerAt &&
          other.enabled == this.enabled &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RemindersCompanion extends UpdateCompanion<Reminder> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> body;
  final Value<int> repeatType;
  final Value<int> hour;
  final Value<int> minute;
  final Value<String> weekdays;
  final Value<int?> monthDay;
  final Value<int?> triggerAt;
  final Value<bool> enabled;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.repeatType = const Value.absent(),
    this.hour = const Value.absent(),
    this.minute = const Value.absent(),
    this.weekdays = const Value.absent(),
    this.monthDay = const Value.absent(),
    this.triggerAt = const Value.absent(),
    this.enabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  RemindersCompanion.insert({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    required int repeatType,
    required int hour,
    required int minute,
    this.weekdays = const Value.absent(),
    this.monthDay = const Value.absent(),
    this.triggerAt = const Value.absent(),
    this.enabled = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : repeatType = Value(repeatType),
       hour = Value(hour),
       minute = Value(minute),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Reminder> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? body,
    Expression<int>? repeatType,
    Expression<int>? hour,
    Expression<int>? minute,
    Expression<String>? weekdays,
    Expression<int>? monthDay,
    Expression<int>? triggerAt,
    Expression<bool>? enabled,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (repeatType != null) 'repeat_type': repeatType,
      if (hour != null) 'hour': hour,
      if (minute != null) 'minute': minute,
      if (weekdays != null) 'weekdays': weekdays,
      if (monthDay != null) 'month_day': monthDay,
      if (triggerAt != null) 'trigger_at': triggerAt,
      if (enabled != null) 'enabled': enabled,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  RemindersCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? body,
    Value<int>? repeatType,
    Value<int>? hour,
    Value<int>? minute,
    Value<String>? weekdays,
    Value<int?>? monthDay,
    Value<int?>? triggerAt,
    Value<bool>? enabled,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      repeatType: repeatType ?? this.repeatType,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      weekdays: weekdays ?? this.weekdays,
      monthDay: monthDay ?? this.monthDay,
      triggerAt: triggerAt ?? this.triggerAt,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (repeatType.present) {
      map['repeat_type'] = Variable<int>(repeatType.value);
    }
    if (hour.present) {
      map['hour'] = Variable<int>(hour.value);
    }
    if (minute.present) {
      map['minute'] = Variable<int>(minute.value);
    }
    if (weekdays.present) {
      map['weekdays'] = Variable<String>(weekdays.value);
    }
    if (monthDay.present) {
      map['month_day'] = Variable<int>(monthDay.value);
    }
    if (triggerAt.present) {
      map['trigger_at'] = Variable<int>(triggerAt.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('repeatType: $repeatType, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('weekdays: $weekdays, ')
          ..write('monthDay: $monthDay, ')
          ..write('triggerAt: $triggerAt, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DrinkLogsTable extends DrinkLogs
    with TableInfo<$DrinkLogsTable, DrinkLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DrinkLogsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _reminderIdMeta = const VerificationMeta(
    'reminderId',
  );
  @override
  late final GeneratedColumn<int> reminderId = GeneratedColumn<int>(
    'reminder_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES reminders (id)',
    ),
  );
  static const VerificationMeta _actionTimeMeta = const VerificationMeta(
    'actionTime',
  );
  @override
  late final GeneratedColumn<DateTime> actionTime = GeneratedColumn<DateTime>(
    'action_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurDateMeta = const VerificationMeta(
    'occurDate',
  );
  @override
  late final GeneratedColumn<String> occurDate = GeneratedColumn<String>(
    'occur_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDrankMeta = const VerificationMeta(
    'isDrank',
  );
  @override
  late final GeneratedColumn<bool> isDrank = GeneratedColumn<bool>(
    'is_drank',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_drank" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    reminderId,
    actionTime,
    occurDate,
    isDrank,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drink_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DrinkLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('reminder_id')) {
      context.handle(
        _reminderIdMeta,
        reminderId.isAcceptableOrUnknown(data['reminder_id']!, _reminderIdMeta),
      );
    }
    if (data.containsKey('action_time')) {
      context.handle(
        _actionTimeMeta,
        actionTime.isAcceptableOrUnknown(data['action_time']!, _actionTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_actionTimeMeta);
    }
    if (data.containsKey('occur_date')) {
      context.handle(
        _occurDateMeta,
        occurDate.isAcceptableOrUnknown(data['occur_date']!, _occurDateMeta),
      );
    } else if (isInserting) {
      context.missing(_occurDateMeta);
    }
    if (data.containsKey('is_drank')) {
      context.handle(
        _isDrankMeta,
        isDrank.isAcceptableOrUnknown(data['is_drank']!, _isDrankMeta),
      );
    } else if (isInserting) {
      context.missing(_isDrankMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DrinkLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DrinkLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      reminderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_id'],
      ),
      actionTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}action_time'],
      )!,
      occurDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occur_date'],
      )!,
      isDrank: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_drank'],
      )!,
    );
  }

  @override
  $DrinkLogsTable createAlias(String alias) {
    return $DrinkLogsTable(attachedDatabase, alias);
  }
}

class DrinkLog extends DataClass implements Insertable<DrinkLog> {
  final int id;
  final int? reminderId;
  final DateTime actionTime;
  final String occurDate;
  final bool isDrank;
  const DrinkLog({
    required this.id,
    this.reminderId,
    required this.actionTime,
    required this.occurDate,
    required this.isDrank,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || reminderId != null) {
      map['reminder_id'] = Variable<int>(reminderId);
    }
    map['action_time'] = Variable<DateTime>(actionTime);
    map['occur_date'] = Variable<String>(occurDate);
    map['is_drank'] = Variable<bool>(isDrank);
    return map;
  }

  DrinkLogsCompanion toCompanion(bool nullToAbsent) {
    return DrinkLogsCompanion(
      id: Value(id),
      reminderId: reminderId == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderId),
      actionTime: Value(actionTime),
      occurDate: Value(occurDate),
      isDrank: Value(isDrank),
    );
  }

  factory DrinkLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DrinkLog(
      id: serializer.fromJson<int>(json['id']),
      reminderId: serializer.fromJson<int?>(json['reminderId']),
      actionTime: serializer.fromJson<DateTime>(json['actionTime']),
      occurDate: serializer.fromJson<String>(json['occurDate']),
      isDrank: serializer.fromJson<bool>(json['isDrank']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'reminderId': serializer.toJson<int?>(reminderId),
      'actionTime': serializer.toJson<DateTime>(actionTime),
      'occurDate': serializer.toJson<String>(occurDate),
      'isDrank': serializer.toJson<bool>(isDrank),
    };
  }

  DrinkLog copyWith({
    int? id,
    Value<int?> reminderId = const Value.absent(),
    DateTime? actionTime,
    String? occurDate,
    bool? isDrank,
  }) => DrinkLog(
    id: id ?? this.id,
    reminderId: reminderId.present ? reminderId.value : this.reminderId,
    actionTime: actionTime ?? this.actionTime,
    occurDate: occurDate ?? this.occurDate,
    isDrank: isDrank ?? this.isDrank,
  );
  DrinkLog copyWithCompanion(DrinkLogsCompanion data) {
    return DrinkLog(
      id: data.id.present ? data.id.value : this.id,
      reminderId: data.reminderId.present
          ? data.reminderId.value
          : this.reminderId,
      actionTime: data.actionTime.present
          ? data.actionTime.value
          : this.actionTime,
      occurDate: data.occurDate.present ? data.occurDate.value : this.occurDate,
      isDrank: data.isDrank.present ? data.isDrank.value : this.isDrank,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DrinkLog(')
          ..write('id: $id, ')
          ..write('reminderId: $reminderId, ')
          ..write('actionTime: $actionTime, ')
          ..write('occurDate: $occurDate, ')
          ..write('isDrank: $isDrank')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, reminderId, actionTime, occurDate, isDrank);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DrinkLog &&
          other.id == this.id &&
          other.reminderId == this.reminderId &&
          other.actionTime == this.actionTime &&
          other.occurDate == this.occurDate &&
          other.isDrank == this.isDrank);
}

class DrinkLogsCompanion extends UpdateCompanion<DrinkLog> {
  final Value<int> id;
  final Value<int?> reminderId;
  final Value<DateTime> actionTime;
  final Value<String> occurDate;
  final Value<bool> isDrank;
  const DrinkLogsCompanion({
    this.id = const Value.absent(),
    this.reminderId = const Value.absent(),
    this.actionTime = const Value.absent(),
    this.occurDate = const Value.absent(),
    this.isDrank = const Value.absent(),
  });
  DrinkLogsCompanion.insert({
    this.id = const Value.absent(),
    this.reminderId = const Value.absent(),
    required DateTime actionTime,
    required String occurDate,
    required bool isDrank,
  }) : actionTime = Value(actionTime),
       occurDate = Value(occurDate),
       isDrank = Value(isDrank);
  static Insertable<DrinkLog> custom({
    Expression<int>? id,
    Expression<int>? reminderId,
    Expression<DateTime>? actionTime,
    Expression<String>? occurDate,
    Expression<bool>? isDrank,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reminderId != null) 'reminder_id': reminderId,
      if (actionTime != null) 'action_time': actionTime,
      if (occurDate != null) 'occur_date': occurDate,
      if (isDrank != null) 'is_drank': isDrank,
    });
  }

  DrinkLogsCompanion copyWith({
    Value<int>? id,
    Value<int?>? reminderId,
    Value<DateTime>? actionTime,
    Value<String>? occurDate,
    Value<bool>? isDrank,
  }) {
    return DrinkLogsCompanion(
      id: id ?? this.id,
      reminderId: reminderId ?? this.reminderId,
      actionTime: actionTime ?? this.actionTime,
      occurDate: occurDate ?? this.occurDate,
      isDrank: isDrank ?? this.isDrank,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (reminderId.present) {
      map['reminder_id'] = Variable<int>(reminderId.value);
    }
    if (actionTime.present) {
      map['action_time'] = Variable<DateTime>(actionTime.value);
    }
    if (occurDate.present) {
      map['occur_date'] = Variable<String>(occurDate.value);
    }
    if (isDrank.present) {
      map['is_drank'] = Variable<bool>(isDrank.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DrinkLogsCompanion(')
          ..write('id: $id, ')
          ..write('reminderId: $reminderId, ')
          ..write('actionTime: $actionTime, ')
          ..write('occurDate: $occurDate, ')
          ..write('isDrank: $isDrank')
          ..write(')'))
        .toString();
  }
}

class $SettingsTableTable extends SettingsTable
    with TableInfo<$SettingsTableTable, SettingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTableTable(this.attachedDatabase, [this._alias]);
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
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsTableData> instance, {
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
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsTableData(
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
  $SettingsTableTable createAlias(String alias) {
    return $SettingsTableTable(attachedDatabase, alias);
  }
}

class SettingsTableData extends DataClass
    implements Insertable<SettingsTableData> {
  final String key;
  final String value;
  const SettingsTableData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsTableCompanion toCompanion(bool nullToAbsent) {
    return SettingsTableCompanion(key: Value(key), value: Value(value));
  }

  factory SettingsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsTableData(
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

  SettingsTableData copyWith({String? key, String? value}) =>
      SettingsTableData(key: key ?? this.key, value: value ?? this.value);
  SettingsTableData copyWithCompanion(SettingsTableCompanion data) {
    return SettingsTableData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsTableData(')
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
      (other is SettingsTableData &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsTableCompanion extends UpdateCompanion<SettingsTableData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsTableCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<SettingsTableData> custom({
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

  SettingsTableCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsTableCompanion(
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
    return (StringBuffer('SettingsTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $DrinkLogsTable drinkLogs = $DrinkLogsTable(this);
  late final $SettingsTableTable settingsTable = $SettingsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    reminders,
    drinkLogs,
    settingsTable,
  ];
}

typedef $$RemindersTableCreateCompanionBuilder =
    RemindersCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> body,
      required int repeatType,
      required int hour,
      required int minute,
      Value<String> weekdays,
      Value<int?> monthDay,
      Value<int?> triggerAt,
      Value<bool> enabled,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$RemindersTableUpdateCompanionBuilder =
    RemindersCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> body,
      Value<int> repeatType,
      Value<int> hour,
      Value<int> minute,
      Value<String> weekdays,
      Value<int?> monthDay,
      Value<int?> triggerAt,
      Value<bool> enabled,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$RemindersTableReferences
    extends BaseReferences<_$AppDatabase, $RemindersTable, Reminder> {
  $$RemindersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DrinkLogsTable, List<DrinkLog>>
  _drinkLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.drinkLogs,
    aliasName: 'reminders__id__drink_logs__reminder_id',
  );

  $$DrinkLogsTableProcessedTableManager get drinkLogsRefs {
    final manager = $$DrinkLogsTableTableManager(
      $_db,
      $_db.drinkLogs,
    ).filter((f) => f.reminderId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_drinkLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
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

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repeatType => $composableBuilder(
    column: $table.repeatType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hour => $composableBuilder(
    column: $table.hour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minute => $composableBuilder(
    column: $table.minute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weekdays => $composableBuilder(
    column: $table.weekdays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get monthDay => $composableBuilder(
    column: $table.monthDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get triggerAt => $composableBuilder(
    column: $table.triggerAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> drinkLogsRefs(
    Expression<bool> Function($$DrinkLogsTableFilterComposer f) f,
  ) {
    final $$DrinkLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.drinkLogs,
      getReferencedColumn: (t) => t.reminderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DrinkLogsTableFilterComposer(
            $db: $db,
            $table: $db.drinkLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
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

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repeatType => $composableBuilder(
    column: $table.repeatType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hour => $composableBuilder(
    column: $table.hour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minute => $composableBuilder(
    column: $table.minute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weekdays => $composableBuilder(
    column: $table.weekdays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get monthDay => $composableBuilder(
    column: $table.monthDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get triggerAt => $composableBuilder(
    column: $table.triggerAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
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

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get repeatType => $composableBuilder(
    column: $table.repeatType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hour =>
      $composableBuilder(column: $table.hour, builder: (column) => column);

  GeneratedColumn<int> get minute =>
      $composableBuilder(column: $table.minute, builder: (column) => column);

  GeneratedColumn<String> get weekdays =>
      $composableBuilder(column: $table.weekdays, builder: (column) => column);

  GeneratedColumn<int> get monthDay =>
      $composableBuilder(column: $table.monthDay, builder: (column) => column);

  GeneratedColumn<int> get triggerAt =>
      $composableBuilder(column: $table.triggerAt, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> drinkLogsRefs<T extends Object>(
    Expression<T> Function($$DrinkLogsTableAnnotationComposer a) f,
  ) {
    final $$DrinkLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.drinkLogs,
      getReferencedColumn: (t) => t.reminderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DrinkLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.drinkLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          Reminder,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (Reminder, $$RemindersTableReferences),
          Reminder,
          PrefetchHooks Function({bool drinkLogsRefs})
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> repeatType = const Value.absent(),
                Value<int> hour = const Value.absent(),
                Value<int> minute = const Value.absent(),
                Value<String> weekdays = const Value.absent(),
                Value<int?> monthDay = const Value.absent(),
                Value<int?> triggerAt = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                title: title,
                body: body,
                repeatType: repeatType,
                hour: hour,
                minute: minute,
                weekdays: weekdays,
                monthDay: monthDay,
                triggerAt: triggerAt,
                enabled: enabled,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                required int repeatType,
                required int hour,
                required int minute,
                Value<String> weekdays = const Value.absent(),
                Value<int?> monthDay = const Value.absent(),
                Value<int?> triggerAt = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => RemindersCompanion.insert(
                id: id,
                title: title,
                body: body,
                repeatType: repeatType,
                hour: hour,
                minute: minute,
                weekdays: weekdays,
                monthDay: monthDay,
                triggerAt: triggerAt,
                enabled: enabled,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RemindersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({drinkLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (drinkLogsRefs) db.drinkLogs],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (drinkLogsRefs)
                    await $_getPrefetchedData<
                      Reminder,
                      $RemindersTable,
                      DrinkLog
                    >(
                      currentTable: table,
                      referencedTable: $$RemindersTableReferences
                          ._drinkLogsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RemindersTableReferences(
                            db,
                            table,
                            p0,
                          ).drinkLogsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.reminderId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      Reminder,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (Reminder, $$RemindersTableReferences),
      Reminder,
      PrefetchHooks Function({bool drinkLogsRefs})
    >;
typedef $$DrinkLogsTableCreateCompanionBuilder =
    DrinkLogsCompanion Function({
      Value<int> id,
      Value<int?> reminderId,
      required DateTime actionTime,
      required String occurDate,
      required bool isDrank,
    });
typedef $$DrinkLogsTableUpdateCompanionBuilder =
    DrinkLogsCompanion Function({
      Value<int> id,
      Value<int?> reminderId,
      Value<DateTime> actionTime,
      Value<String> occurDate,
      Value<bool> isDrank,
    });

final class $$DrinkLogsTableReferences
    extends BaseReferences<_$AppDatabase, $DrinkLogsTable, DrinkLog> {
  $$DrinkLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RemindersTable _reminderIdTable(_$AppDatabase db) =>
      db.reminders.createAlias('drink_logs__reminder_id__reminders__id');

  $$RemindersTableProcessedTableManager? get reminderId {
    final $_column = $_itemColumn<int>('reminder_id');
    if ($_column == null) return null;
    final manager = $$RemindersTableTableManager(
      $_db,
      $_db.reminders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_reminderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DrinkLogsTableFilterComposer
    extends Composer<_$AppDatabase, $DrinkLogsTable> {
  $$DrinkLogsTableFilterComposer({
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

  ColumnFilters<DateTime> get actionTime => $composableBuilder(
    column: $table.actionTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occurDate => $composableBuilder(
    column: $table.occurDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDrank => $composableBuilder(
    column: $table.isDrank,
    builder: (column) => ColumnFilters(column),
  );

  $$RemindersTableFilterComposer get reminderId {
    final $$RemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reminderId,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableFilterComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DrinkLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $DrinkLogsTable> {
  $$DrinkLogsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get actionTime => $composableBuilder(
    column: $table.actionTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occurDate => $composableBuilder(
    column: $table.occurDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDrank => $composableBuilder(
    column: $table.isDrank,
    builder: (column) => ColumnOrderings(column),
  );

  $$RemindersTableOrderingComposer get reminderId {
    final $$RemindersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reminderId,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableOrderingComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DrinkLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DrinkLogsTable> {
  $$DrinkLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get actionTime => $composableBuilder(
    column: $table.actionTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get occurDate =>
      $composableBuilder(column: $table.occurDate, builder: (column) => column);

  GeneratedColumn<bool> get isDrank =>
      $composableBuilder(column: $table.isDrank, builder: (column) => column);

  $$RemindersTableAnnotationComposer get reminderId {
    final $$RemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reminderId,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableAnnotationComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DrinkLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DrinkLogsTable,
          DrinkLog,
          $$DrinkLogsTableFilterComposer,
          $$DrinkLogsTableOrderingComposer,
          $$DrinkLogsTableAnnotationComposer,
          $$DrinkLogsTableCreateCompanionBuilder,
          $$DrinkLogsTableUpdateCompanionBuilder,
          (DrinkLog, $$DrinkLogsTableReferences),
          DrinkLog,
          PrefetchHooks Function({bool reminderId})
        > {
  $$DrinkLogsTableTableManager(_$AppDatabase db, $DrinkLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DrinkLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DrinkLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DrinkLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> reminderId = const Value.absent(),
                Value<DateTime> actionTime = const Value.absent(),
                Value<String> occurDate = const Value.absent(),
                Value<bool> isDrank = const Value.absent(),
              }) => DrinkLogsCompanion(
                id: id,
                reminderId: reminderId,
                actionTime: actionTime,
                occurDate: occurDate,
                isDrank: isDrank,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> reminderId = const Value.absent(),
                required DateTime actionTime,
                required String occurDate,
                required bool isDrank,
              }) => DrinkLogsCompanion.insert(
                id: id,
                reminderId: reminderId,
                actionTime: actionTime,
                occurDate: occurDate,
                isDrank: isDrank,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DrinkLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({reminderId = false}) {
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
                    if (reminderId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.reminderId,
                                referencedTable: $$DrinkLogsTableReferences
                                    ._reminderIdTable(db),
                                referencedColumn: $$DrinkLogsTableReferences
                                    ._reminderIdTable(db)
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

typedef $$DrinkLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DrinkLogsTable,
      DrinkLog,
      $$DrinkLogsTableFilterComposer,
      $$DrinkLogsTableOrderingComposer,
      $$DrinkLogsTableAnnotationComposer,
      $$DrinkLogsTableCreateCompanionBuilder,
      $$DrinkLogsTableUpdateCompanionBuilder,
      (DrinkLog, $$DrinkLogsTableReferences),
      DrinkLog,
      PrefetchHooks Function({bool reminderId})
    >;
typedef $$SettingsTableTableCreateCompanionBuilder =
    SettingsTableCompanion Function({
      required String key,
      Value<String> value,
      Value<int> rowid,
    });
typedef $$SettingsTableTableUpdateCompanionBuilder =
    SettingsTableCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableFilterComposer({
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

class $$SettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableOrderingComposer({
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

class $$SettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableAnnotationComposer({
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

class $$SettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTableTable,
          SettingsTableData,
          $$SettingsTableTableFilterComposer,
          $$SettingsTableTableOrderingComposer,
          $$SettingsTableTableAnnotationComposer,
          $$SettingsTableTableCreateCompanionBuilder,
          $$SettingsTableTableUpdateCompanionBuilder,
          (
            SettingsTableData,
            BaseReferences<
              _$AppDatabase,
              $SettingsTableTable,
              SettingsTableData
            >,
          ),
          SettingsTableData,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableTableManager(_$AppDatabase db, $SettingsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  SettingsTableCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsTableCompanion.insert(
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

typedef $$SettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTableTable,
      SettingsTableData,
      $$SettingsTableTableFilterComposer,
      $$SettingsTableTableOrderingComposer,
      $$SettingsTableTableAnnotationComposer,
      $$SettingsTableTableCreateCompanionBuilder,
      $$SettingsTableTableUpdateCompanionBuilder,
      (
        SettingsTableData,
        BaseReferences<_$AppDatabase, $SettingsTableTable, SettingsTableData>,
      ),
      SettingsTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$DrinkLogsTableTableManager get drinkLogs =>
      $$DrinkLogsTableTableManager(_db, _db.drinkLogs);
  $$SettingsTableTableTableManager get settingsTable =>
      $$SettingsTableTableTableManager(_db, _db.settingsTable);
}
