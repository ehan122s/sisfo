// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AnnouncementModel _$AnnouncementModelFromJson(Map<String, dynamic> json) =>
    _AnnouncementModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      targetRole: json['target_role'] as String?,
      isActive: json['is_active'] as bool?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$AnnouncementModelToJson(_AnnouncementModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'target_role': instance.targetRole,
      'is_active': instance.isActive,
      'created_at': instance.createdAt?.toIso8601String(),
    };
