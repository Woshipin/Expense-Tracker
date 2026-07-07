# Sunset Expense Tracker — 简历项目总结

## 📌 项目简介

**Sunset Expense Tracker** 是一个全栈个人财务管理系统，采用 **Laravel + Next.js + Flutter** 三端架构，支持 Web 和移动端使用。用户可追踪收支、管理预算、通过 AI 获取个性化财务建议。

**项目地址**: https://github.com/Woshipin/Expense-Tracker

---

## 🛠 技术栈

| 层级 | 技术 |
|------|------|
| **后端** | Laravel 12, PHP, MySQL, JWT Auth, Laravel Socialite, Groq AI API |
| **前端 Web** | Next.js 15, TypeScript, Tailwind CSS, Recharts, Axios, Capacitor |
| **移动端** | Flutter, Dart, Dio, fl_chart, SharedPreferences |
| **工具** | Git, Composer, npm, VS Code |

---

## 🎯 核心功能

### 1. 用户认证系统
- 邮箱密码注册/登录 + JWT Token 认证
- Google/Facebook 第三方快捷登录
- 忘记密码/重置密码（邮件验证）
- 4级角色权限（Super Admin / Admin / Premium / Basic）
- 账号状态管理（激活/禁用）

### 2. 财务管理
- **支出/收入记录**: 完整的 CRUD，支持标题、金额、日期、分类、支付方式
- **智能筛选**: 按分类、支付方式、日期范围、关键词搜索
- **分页展示**: 每页5条，按时间倒序

### 3. 仪表盘（Dashboard）
- 4大核心指标卡片：余额、总收入、总支出、储蓄率
- 7天收支趋势面积图
- 前5大支出分类环形图
- 最近收支记录
- 预算进度条（含超支提醒）

### 4. 预算管理
- 按月/年/分类设定预算上限
- 实时计算实际花费与剩余金额
- 进度百分比可视化
- 超支自动标记

### 5. 日历视图
- 月历模式展示每日收支汇总
- 支出/收入颜色区分

### 6. AI 智能财务顾问
- 集成 Groq API (Llama 3.3 70B)
- 自动注入用户真实财务数据到 AI 上下文
- 支持多语言对话
- Markdown 格式化输出
- 提供个性化省钱建议和财务分析

### 7. 分类与支付方式管理
- 支持自定义图标和颜色
- 绑定收支类型（Expense/Income）
- 启用/禁用状态管理

### 8. 个人资料管理
- 头像上传（自动删除旧头像）
- 修改密码（需验证当前密码）
- 图片代理服务（解决跨域问题）

### 9. 用户管理（Admin）
- 管理员可查看/新增/编辑/删除用户

---

## 🏗 系统架构亮点

```
[Next.js Web] ──→ [Laravel API] ──→ [MySQL]
[Flutter App] ──→ [Laravel API] ──→ [MySQL]
       ↓
[Groq AI (Llama 3.3)]
```

- **前后端分离**: RESTful API 设计，JSON 数据交互
- **多端统一**: Web 和移动端共用同一套后端 API
- **智能 IP 探测**: 前端自动扫描局域网内可用的后端地址，支持多设备调试

---

## 🔒 安全设计

- JWT Token 认证（HttpOnly Cookie + Bearer Token）
- 数据隔离：所有查询强制绑定当前用户 ID
- 外键归属验证：只能使用自己的分类和支付方式
- 联合唯一约束：防止重复数据
- 软删除：用户数据可恢复
- 密码安全：第三方登录用户无法修改密码

---

## 🎨 UI/UX 设计

- **品牌主题**: "Sunset" 日落概念，橙色渐变主色调
- **响应式布局**: 桌面可折叠侧边栏 + 移动端底部导航
- **组件库**: 自定义 Card、Button、Modal、Toast 组件
- **数据可视化**: Recharts 面积图/饼图、fl_chart 图表

---

## 📊 数据库设计（7张核心表）

| 表名 | 说明 |
|------|------|
| `users` | 用户（角色、状态、软删除、第三方登录） |
| `expenses` | 支出记录 |
| `incomes` | 收入记录 |
| `categories` | 分类（图标、颜色、绑定类型） |
| `payment_methods` | 支付方式（图标、颜色、绑定类型） |
| `types` | 收支类型（Expense/Income） |
| `budgets` | 预算（月份、年份、金额） |

---

## 🚀 开发环境启动

```bash
# 后端
cd backend && composer install && php artisan serve

# 前端 Web
cd frontend && npm install && npm run dev

# 移动端
cd tracker_app && flutter pub get && flutter run
```

---

## 💡 个人贡献（示例 — 根据实际情况修改）

- 独立完成全栈架构设计与开发
- 实现 JWT 认证 + 第三方登录集成
- 开发 AI 财务顾问功能（Groq API 集成）
- 设计响应式 UI 组件库
- 实现多端 API 地址自动探测
- 数据库设计与优化
- 安全防护（数据隔离、验证规则、权限控制）