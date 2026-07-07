# Sunset Expense Tracker — 完整项目文档

## 📋 项目概述

**Sunset Expense Tracker** 是一个全功能的个人财务管理系统，帮助用户追踪收入与支出、管理预算、获取 AI 智能财务建议。项目采用前后端分离架构，同时支持 Web 和移动端。

---

## 🏗 系统架构

```
┌─────────────────────────────────────────────────────┐
│                   Frontend (Next.js)                  │
│                  http://localhost:3000                │
├──────────────────────┬──────────────────────────────┤
│   Web App (PC/Mobile)│   Mobile App (Flutter)        │
└──────────┬───────────┴──────────┬───────────────────┘
           │                      │
           │    REST API (JSON)   │
           └──────────┬───────────┘
                      │
           ┌──────────▼───────────┐
           │  Backend (Laravel)   │
           │  http://127.0.0.1:8000 │
           ├──────────────────────┤
           │      MySQL / MariaDB │
           └──────────────────────┘
```

---

# 一、Backend（Laravel PHP 后端）

## 技术栈
- **框架**: Laravel 11.x
- **认证**: JWT (php-open-source-saver/jwt-auth)
- **数据库**: MySQL/MariaDB
- **第三方登录**: Laravel Socialite (Google, Facebook)
- **AI 集成**: Groq API (Llama 3.3 70B)
- **密码重置**: Laravel Password Broker

## 数据库 Models

| Model | 表名 | 说明 |
|-------|------|------|
| **User** | users | 用户（支持角色、状态、软删除、第三方登录） |
| **Expense** | expenses | 支出记录 |
| **Income** | incomes | 收入记录 |
| **Category** | categories | 分类（绑定收支类型，含图标和颜色） |
| **PaymentMethod** | payment_methods | 支付方式（绑定收支类型，含图标和颜色） |
| **Type** | types | 收支类型（Expense/Income） |
| **Budget** | budgets | 预算（按月/年/分类设定） |

### User 模型
- `full_name`, `email`, `password` — 基本认证信息
- `role` — 权限等级: 0=Super Admin, 1=Admin, 2=Premium, 3=Basic
- `status` — 0=禁用, 1=激活
- `currency` — 货币设置
- `image_path` — 头像 URL
- `provider`, `provider_id` — 第三方登录信息 (Google/Facebook)
- **JWT 支持**: 实现 `JWTSubject` 接口，Token 中含自定义 claims

### Expense / Income 模型
- `title`, `description` — 描述信息
- `price` — 金额
- `date`, `time` — 时间戳
- `payment_method_id` — 关联支付方式
- `category_id` — 关联分类
- `user_id` — 关联用户（数据隔离）

### Category / PaymentMethod 模型
- `name`, `description` — 基本信息
- `type_id` — 绑定收支类型 (Expense/Income)
- `icon`, `color` — 图标和颜色（便于前端展示）
- `status` — 启用/禁用
- `user_id` — 用户隔离

### Type 模型
- `name` — 类型名称（如 "Expense", "Income"）
- `status` — 启用/禁用

### Budget 模型
- `user_id` — 用户
- `category_id` — 分类
- `amount` — 预算金额
- `month`, `year` — 指定月份/年份

## Controllers（控制器）

### 1. AuthController — 认证管理
- **register()**: 用户注册（姓名、邮箱、密码）
- **login()**: 邮箱密码登录（支持 Remember Me 30天）
- **redirectToProvider()**: 第三方登录跳转（Google/Facebook）
- **handleProviderCallback()**: 第三方登录回调处理
- **sendResetLinkEmail()**: 发送密码重置邮件
- **resetPassword()**: 执行密码重置
- **me()**: 获取当前登录用户信息
- **logout()**: 退出登录（清除 JWT Cookie）
- **refresh()**: 刷新 JWT Token

### 2. DashboardController — 仪表盘
- **index()**: 返回完整的仪表盘数据，包含：
  - 当月总收入、总支出、净余额、储蓄率
  - 7天收支趋势折线图数据
  - 前5大支出分类饼图
  - 最近5笔支出记录
  - 最近5笔收入记录
  - 当月预算状态（含进度百分比）

### 3. ExpenseController — 支出管理
- **index()**: 分页列表（支持搜索、按分类/支付方式/日期筛选）
- **store()**: 新增支出（强验证：分类和支付方式必须属于当前用户）
- **update()**: 修改支出（只能修改自己的）
- **destroy()**: 删除支出

### 4. IncomeController — 收入管理
- 与 ExpenseController 结构相同
- 支持相同的搜索与筛选功能

### 5. CategoryController — 分类管理
- **index()**: 分页列表（支持搜索、状态筛选）
- **store()**: 新增分类（联合唯一：同一用户同一类型下不可重名）
- **update()**: 修改分类
- **destroy()**: 删除分类

### 6. PaymentMethodController — 支付方式管理
- 与 CategoryController 结构相同
- 支持图标、颜色、状态管理

### 7. TypeController — 收支类型管理
- 完整的 CRUD
- 管理 "Expense" 和 "Income" 类型

### 8. BudgetController — 预算管理
- **index()**: 获取预算列表（含实际花费、剩余金额、使用百分比）
- **store()**: 创建预算（同月份同分类不可重复）
- **show()**: 预算详情
- **update()**: 更新预算
- **destroy()**: 删除预算

### 9. CalendarController — 日历视图
- **index()**: 按年月合并返回支出和收入（带类型标记）

### 10. AiInsightsController — AI 智能分析
- **getInsights()**: 返回指定日期范围的财务数据统计
- **chat()**: AI 财务顾问对话功能
  - 从数据库查询真实财务数据
  - 构建 System Prompt 嵌入用户数据
  - 调用 Groq API (Llama 3.3 70B)
  - 支持语言自适应、Markdown 格式化

### 11. ProfileController — 个人资料
- **updateProfile()**: 更新姓名、邮箱、头像（上传 + 自动删除旧头像）
- **updatePassword()**: 修改密码（需验证当前密码）
- **serveImage()**: 图片代理（解决 Flutter Web 跨域问题）

### 12. UserController — 用户管理（Admin）
- 完整的用户 CRUD，仅管理员可访问

## Middleware
- **JwtCookieToHeader**: 将 Cookie 中的 `jwt_token` 提取到 Authorization Header

## API Routes

| Method | Endpoint | 说明 | 鉴权 |
|--------|----------|------|------|
| POST | `/api/register` | 注册 | 公开 |
| POST | `/api/login` | 登录 | 公开 |
| GET | `/api/auth/{provider}` | 第三方登录 | 公开 |
| GET | `/api/auth/{provider}/callback` | 第三方回调 | 公开 |
| POST | `/api/forgot-password` | 忘记密码 | 公开 |
| POST | `/api/reset-password` | 重置密码 | 公开 |
| GET | `/api/me` | 当前用户 | 登录 |
| POST | `/api/logout` | 退出 | 登录 |
| POST | `/api/refresh` | 刷新 Token | 登录 |
| PUT | `/api/profile` | 更新资料 | 登录 |
| PUT | `/api/profile/password` | 修改密码 | 登录 |
| GET | `/api/dashboard` | 仪表盘 | 登录 |
| GET | `/api/ai-insights` | AI 分析数据 | 登录 |
| POST | `/api/ai-insights/chat` | AI 对话 | 登录 |
| GET/POST/PUT/DELETE | `/api/users` | 用户管理 | Admin |
| GET/POST/PUT/DELETE | `/api/categories` | 分类管理 | 登录 |
| GET/POST/PUT/DELETE | `/api/payment-methods` | 支付方式管理 | 登录 |
| GET/POST/PUT/DELETE | `/api/expenses` | 支出管理 | 登录 |
| GET/POST/PUT/DELETE | `/api/incomes` | 收入管理 | 登录 |
| GET/POST/PUT/DELETE | `/api/types` | 类型管理 | 登录 |
| GET/POST/PUT/DELETE | `/api/budget/*` | 预算管理 | 登录 |
| GET | `/api/calendar` | 日历数据 | 登录 |
| GET | `/api/images/{file}` | 图片代理 | 公开 |

---

# 二、Frontend（Next.js TypeScript 前端）

## 技术栈
- **框架**: Next.js 15 (App Router + Client Components)
- **语言**: TypeScript
- **样式**: Tailwind CSS + Lucide Icons
- **图表**: Recharts (AreaChart, PieChart)
- **HTTP 客户端**: Axios
- **移动端**: Capacitor (Android 原生支持)
- **AI 前端**: react-markdown

## 核心组件

### SidebarLayout（主布局）
- 响应式侧边栏（可折叠）
- 桌面端：左侧完整导航菜单
- 移动端：底部导航栏 + "更多"弹出菜单
- 路由守卫：未登录自动跳转登录页
- 导航项：
  - Dashboard / AI Insights / Users / Calendar
  - Expenses / Income / Budget
  - Settings（下拉）：Profile / Types / Categories / Payment Methods

### 页面列表

| 页面 | 路由 | 功能 |
|------|------|------|
| **Dashboard** | `/dashboard` | 4大核心指标卡片、7天趋势图、分类饼图、最近收支、预算状态 |
| **AI Insights** | `/ai-insights` | 财务数据分析 + AI 聊天顾问 |
| **Expenses** | `/expenses` | 支出记录 CRUD |
| **Income** | `/income` | 收入记录 CRUD |
| **Budget** | `/budget` | 预算管理 (按月/年/分类) |
| **Calendar** | `/calendar` | 月历视图（收支汇总） |
| **Categories** | `/categories` | 分类管理 |
| **Payment Methods** | `/payment-methods` | 支付方式管理 |
| **Types** | `/types` | 收支类型管理 |
| **Profile** | `/profile` | 个人资料与密码设置 |
| **Users** | `/users` | 用户管理 (Admin) |
| **Login** | `/login` | 登录 |
| **Register** | `/register` | 注册 |
| **Forgot Password** | `/forgot-password` | 忘记密码 |
| **Reset Password** | `/reset-password` | 重置密码 |

### Dashboard 页面详情
- **指标卡片**: Balance(余额)、Income(收入)、Expenses(支出)、Savings Rate(储蓄率)
- **趋势图**: 近7天收支对比面积图
- **分类饼图**: 本月前5大支出分类环形图
- **最近支出**: 最新5笔支出
- **最近收入**: 最新5笔收入
- **预算状态**: 总体预算进度 + 各分类详细预算条

### 工具函数
- `lib/axios.ts`: Axios 实例，支持 API 地址自动探测（局域网多设备支持）、本地 Token 管理
- `lib/utils.ts`: 通用工具函数

### UI 组件
- `components/ui.tsx`: Card, Button, Modal, Toast 等基础组件
- `components/ui/select.tsx`: 下拉选择器
- `components/SidebarLayout.tsx`: 应用主布局

---

# 三、Tracker App（Flutter/Dart 移动端）

## 技术栈
- **框架**: Flutter (Material 3)
- **语言**: Dart
- **HTTP**: Dio (支持拦截器)
- **图表**: fl_chart
- **存储**: SharedPreferences
- **AI 展示**: flutter_markdown
- **图片**: image_picker
- **工具**: intl, url_launcher

## 核心功能
- 与 Web 前端功能完全一致
- Web URL 策略（去除 `#` 哈希）
- 启动时自动探测后端 API 地址
- 支持 Web 端部署（与 App 共用代码）

## 目录结构
```
lib/
├── main.dart                        # 应用入口
├── core/
│   ├── api/api_client.dart          # Dio HTTP 客户端
│   ├── constants/colors.dart        # Sunset 主题色
│   └── widgets/                     # 通用组件
├── views/
│   ├── main_layout.dart             # 主导航布局
│   ├── auth/                        # 登录/注册/重置密码
│   ├── dashboard/                   # 仪表盘
│   ├── ai_insights/                 # AI 智能分析
│   ├── expenses/                    # 支出管理
│   ├── income/                      # 收入管理
│   ├── budgets/                     # 预算管理
│   ├── calendar/                    # 日历视图
│   ├── categories/                  # 分类管理
│   ├── payment_methods/             # 支付方式管理
│   ├── types/                       # 收支类型管理
│   ├── profile/                     # 个人资料
│   ├── users/                       # 用户管理
│   └── shared/                      # 共享组件
```

---

# 四、UI/UX 设计与主题

## 品牌概念: "Sunset"（日落）
- 主色调: 橙色渐变 (#f97316 → #ea580c)
- 背景: 浅橙/浅红渐变 (orange-50 → red-50 → orange-100)
- 风格: 圆角大卡片 (rounded-2xl)、毛玻璃效果 (backdrop-blur)、柔和阴影
- 品牌标志: `+` 符号（琥珀色图标）

## 响应式设计
- 桌面端: 可折叠侧边栏 (w-64 ↔ w-20)
- 平板/移动端: 底部导航栏 + 弹出式更多菜单
- 全平台一致的用户体验

---

# 五、安全特性

1. **JWT 认证**: Token 存储在 Cookie（HttpOnly） + localStorage
2. **数据隔离**: 所有查询强制加上 `user_id = auth()->id()`
3. **验证规则**: 外键存在性验证 + 归属验证（只能使用自己的分类/支付方式）
4. **防止重复**: 分类名联合唯一、预算同月份不重复
5. **软删除**: 用户表支持软删除
6. **角色权限**: 4级权限 (Super Admin / Admin / Premium / Basic)
7. **账号状态**: 禁用账号无法登录
8. **密码安全**: 第三方登录用户无法修改密码

---

# 六、AI 智能分析

- **引擎**: Groq API (Llama 3.3-70b-versatile)
- **功能**: 基于用户真实财务数据的智能对话
- **System Prompt**: 自动注入用户数据（收支统计、分类明细、预算状态）
- **特点**: 多语言自适应、Markdown 格式化输出、金融顾问角色
- **前端展示**: 使用 react-markdown / flutter_markdown 渲染

---

# 七、开发环境

### 后端启动
```bash
cd backend
cp .env.example .env        # 配置数据库和 API 密钥
composer install
php artisan key:generate
php artisan migrate
php artisan serve
```

### 前端启动
```bash
cd frontend
npm install
npm run dev
```

### Flutter 启动
```bash
cd tracker_app
flutter pub get
flutter run -d chrome   # Web
flutter run -d android  # Android
```

### API 地址自动探测
前端和 Flutter App 启动时会自动探测可用的后端 API 地址：
- `http://127.0.0.1:8000/api`（本地）
- 局域网 IP 列表轮询
- 探测成功后永久缓存，不再重复扫网