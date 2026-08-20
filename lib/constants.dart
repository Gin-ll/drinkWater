/// 全局可配置常量
library;

/// 手动喝水自动完成提醒的时间窗口：
/// 提醒时间前后 [reminderMatchWindow] 内存在一条手动喝水记录，
/// 则该提醒自动判定为「已喝水」，避免刚喝完又提醒。
const Duration reminderMatchWindow = Duration(minutes: 30);
