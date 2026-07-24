"use client";
import { usePathname, useRouter } from "next/navigation";
import {
  LayoutDashboard, ReceiptText, PieChart, Settings, LogOut,
  Calendar, DollarSign, BarChart3, ChevronLeft,
  ChevronRight, Tags, CreditCard, Users, Loader2, Layers,
  ChevronDown, ChevronUp, User
} from 'lucide-react';
import React, { useState, useEffect } from "react";
import { Modal, Button, Toast } from "@/components/ui";
import api, { findWorkingApiURL } from "@/lib/axios";

export default function SidebarLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  
  const safePathname = pathname || "";

  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  
  // 移动端菜单状态
  const [isMobileTransactionsOpen, setIsMobileTransactionsOpen] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  
  const [isLogoutModalOpen, setIsLogoutModalOpen] = useState(false);
  const [isTransactionsOpen, setIsTransactionsOpen] = useState(false); // 桌面端 Transactions Dropdown
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' | 'warning' } | null>(null);

  const [user, setUser] = useState<any>(null);
  const [isCheckingAuth, setIsCheckingAuth] = useState(true);

  const isAuthPage = ['/login', '/register', '/forgot-password', '/reset-password'].includes(safePathname);
  
  // Transactions 下拉包含的子路径
  const transactionSubPaths = ['/expenses', '/income', '/types', '/categories', '/payment-methods'];
  const isTransactionsActive = transactionSubPaths.some(p => safePathname === p || safePathname.startsWith(p));

  // 路由如果在 Transactions 组内，自动展开 Dropdown
  useEffect(() => {
    if (isTransactionsActive) setIsTransactionsOpen(true);
  }, [isTransactionsActive]);

  // 首次载入初始化鉴权
  useEffect(() => {
    let isMounted = true;

    const initializeAuth = async () => {
      try {
        await findWorkingApiURL();
        const response = await api.get('/me');
        if (isMounted) {
          setUser(response.data);
        }
      } catch (error) {
        if (isMounted) {
          setUser(null);
        }
      } finally {
        if (isMounted) {
          setIsCheckingAuth(false);
        }
      }
    };

    initializeAuth();

    return () => {
      isMounted = false;
    };
  }, []);

  // 路由守卫
  useEffect(() => {
    if (isCheckingAuth) return;

    const token = typeof window !== "undefined" ? localStorage.getItem("auth_token") : null;

    if (!token) {
      if (!isAuthPage) {
        router.replace('/login');
      }
    } else {
      if (!user) {
        const fetchUserAfterLogin = async () => {
          setIsCheckingAuth(true);
          try {
            const response = await api.get('/me');
            setUser(response.data);
          } catch (e) {
            setUser(null);
            localStorage.removeItem("auth_token");
            router.replace('/login');
          } finally {
            setIsCheckingAuth(false);
          }
        };
        fetchUserAfterLogin();
      } else {
        if (isAuthPage) {
          router.replace('/dashboard');
        }
      }
    }
  }, [safePathname, user, isCheckingAuth, isAuthPage, router]);

  const getRoleName = (role: number) => {
    switch (role) {
      case 0: return 'Super Admin';
      case 1: return 'Admin';
      case 2: return 'Premium';
      case 3: return 'Basic';
      default: return 'User';
    }
  };

  const handleLogout = async () => {
    try {
      await api.post('/logout');
    } catch (error) {
      console.error("Logout error", error);
    } finally {
      localStorage.removeItem("auth_token");
      setIsLogoutModalOpen(false);
      setToast({ message: "Logout successful! Redirecting to login...", type: 'success' });
      
      setTimeout(() => {
        setUser(null);
        router.replace('/login');
      }, 1500);
    }
  };

  if (isCheckingAuth) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center bg-gradient-to-br from-orange-50 via-red-50 to-orange-100">
        <Loader2 className="w-12 h-12 text-orange-500 animate-spin mb-4" />
        <p className="text-gray-500 font-medium">Verifying access...</p>
        {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
      </div>
    );
  }

  if (isAuthPage) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-orange-50 via-red-50 to-orange-100 selection:bg-sunset-primary/20">
        {children}
      </div>
    );
  }

  const isActive = (id: string) => safePathname === id || (safePathname.startsWith(id) && id !== '/');
  const canSeeUsers = user?.role === 0 || user?.role === 1;

  // 1. 桌面端主导航列表 (排序: Dashboard -> AI Insights -> Users -> Calendar -> Budget)
  const desktopNavItems = [
    { id: '/dashboard',   label: 'Dashboard',   icon: LayoutDashboard, show: true },
    { id: '/ai-insights', label: 'AI Insights', icon: BarChart3,       show: true },
    { id: '/users',       label: 'Users',       icon: Users,           show: canSeeUsers },
    { id: '/calendar',    label: 'Calendar',    icon: Calendar,        show: true },
    { id: '/budget',      label: 'Budget',      icon: PieChart,        show: true },
  ];

  // 2. Transactions Dropdown 子菜单
  const transactionSubItems = [
    { id: '/expenses',        label: 'Expenses',        icon: ReceiptText },
    { id: '/income',          label: 'Income',          icon: DollarSign },
    { id: '/types',           label: 'Types',           icon: Layers },
    { id: '/categories',      label: 'Categories',      icon: Tags },
    { id: '/payment-methods', label: 'Payment Methods', icon: CreditCard },
  ];

  // 3. 移动端底部导航栏项 (顺序: Dashboard -> AI Insights -> Calendar -> Transactions -> Settings)
  const mobileBottomNavItems = [
    { id: '/dashboard',          label: 'Dash',         icon: LayoutDashboard },
    { id: '/ai-insights',        label: 'AI',           icon: BarChart3 },
    { id: '/calendar',           label: 'Calendar',     icon: Calendar },
    { id: 'transactions_menu',   label: 'Transactions', icon: ReceiptText }, 
    { id: 'settings_menu',       label: 'Settings',     icon: Settings }, 
  ];

  const moreMenuPaths = ['/profile', '/budget', '/users'];

  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-50 via-red-50 to-orange-100 flex selection:bg-sunset-primary/20">
      
      {/* =========================================================================
          Desktop Sidebar
      ========================================================================= */}
      <aside 
        className={`hidden md:flex flex-col bg-gradient-to-b from-orange-100/90 via-orange-50/90 to-red-100/90 backdrop-blur-md shadow-[4px_0_24px_rgba(234,88,12,0.08)] border-0 transition-all duration-300 relative z-40 ${isSidebarOpen ? "w-64" : "w-20"}`}
      >
        {/* Brand Header */}
        <div className="p-6 flex items-center gap-3 overflow-hidden">
          <div className="w-10 h-10 rounded-[12px] bg-amber-400 text-sunset-dark flex flex-shrink-0 items-center justify-center font-bold text-2xl shadow-sm tracking-tight">+</div>
          {isSidebarOpen && (
            <div className="flex flex-col items-start leading-tight">
              <span className="font-extrabold text-sunset-dark text-xl tracking-tight shrink-0 whitespace-nowrap">Sunset</span>
              <span className="text-[9px] font-bold text-sunset-dark/40 tracking-wider">EXPENSE TRACKER</span>
            </div>
          )}
        </div>

        {/* User Card (带 Profile 按钮和 Hover Tooltip) */}
        <div className="px-4 mb-4 shrink-0">
          <div 
            className={`rounded-2xl border border-orange-300 bg-white/40 flex items-center justify-between transition-all overflow-hidden ${isSidebarOpen ? "p-3 gap-2" : "justify-center p-2"}`}
          >
            <div className="flex items-center gap-2.5 min-w-0 flex-1">
              <div className="w-8 h-8 rounded-full bg-gradient-to-br from-[#f89c8a] to-red-500 flex items-center justify-center text-white font-bold shrink-0 shadow-sm uppercase text-sm">
                {user?.full_name ? user.full_name.charAt(0) : 'U'}
              </div>
              {isSidebarOpen && (
                <div className="flex flex-col leading-tight min-w-0 flex-1">
                  <span className="font-bold text-black text-sm whitespace-nowrap truncate" title={user?.full_name}>{user?.full_name || 'User'}</span>
                  <span className="text-[10px] font-bold text-orange-600 uppercase tracking-widest mt-0.5">
                    {getRoleName(user?.role)}
                  </span>
                </div>
              )}
            </div>

            {/* Profile 图标按钮与 Hover 提示 */}
            {isSidebarOpen && (
              <button
                onClick={() => router.push('/profile')}
                className="p-1.5 rounded-xl hover:bg-orange-200/60 text-sunset-dark/70 hover:text-orange-600 transition-all relative group shrink-0"
                title="Profile"
              >
                <User size={18} strokeWidth={2.5} />
                <span className="absolute left-1/2 -translate-x-1/2 top-full mt-1.5 px-2 py-1 bg-sunset-dark text-white text-[10px] font-bold rounded-lg opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none z-50 whitespace-nowrap shadow-md">
                  Profile
                </span>
              </button>
            )}
          </div>
        </div>

        {/* Expand / Collapse Button */}
        <button
          onClick={() => setIsSidebarOpen(!isSidebarOpen)}
          className="absolute -right-3 top-8 w-6 h-6 bg-white border border-orange-300 rounded-full flex items-center justify-center text-sunset-dark hover:text-orange-500 shadow-sm z-50"
        >
          {isSidebarOpen ? <ChevronLeft size={14} /> : <ChevronRight size={14} />}
        </button>

        {/* Navigation Section */}
        <nav className="px-4 py-2 space-y-1 overflow-y-auto custom-scrollbar flex-1">
          
          {/* 常规单项菜单：Dashboard, AI Insights, Users, Calendar, Budget */}
          {desktopNavItems.filter(i => i.show).map((item) => (
            <button
              key={item.id}
              onClick={() => router.push(item.id)}
              className={`w-full flex items-center justify-between gap-3 rounded-2xl font-bold transition-all duration-200 group relative outline-none ${isSidebarOpen ? "px-4 py-3" : "justify-center p-3"} ${isActive(item.id) ? "bg-gradient-to-br from-sunset-primary to-sunset-secondary text-white shadow-md" : "text-black hover:bg-white/50"}`}
            >
              <div className="flex items-center gap-3">
                <item.icon
                  size={20} strokeWidth={2.5}
                  className={`shrink-0 transition-colors ${isActive(item.id) ? "text-white" : "text-black group-hover:text-sunset-primary"}`}
                />
                {isSidebarOpen && <span className="whitespace-nowrap">{item.label}</span>}
              </div>
              {isActive(item.id) && isSidebarOpen && <div className="w-1.5 h-1.5 rounded-full bg-white shrink-0" />}

              {!isSidebarOpen && (
                <div className="absolute left-full ml-4 px-3 py-2 bg-sunset-dark text-white text-sm font-medium rounded-xl opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all whitespace-nowrap z-50">
                  {item.label}
                </div>
              )}
            </button>
          ))}

          {/* Transactions 下拉菜单：包含 Expenses, Income, Types, Categories, Payment Methods */}
          <div>
            <button
              onClick={() => {
                if (isSidebarOpen) {
                  setIsTransactionsOpen(prev => !prev);
                } else {
                  router.push('/expenses');
                }
              }}
              className={`w-full flex items-center justify-between gap-3 rounded-2xl font-bold transition-all duration-200 group relative outline-none ${isSidebarOpen ? "px-4 py-3" : "justify-center p-3"} ${isTransactionsActive ? "bg-gradient-to-br from-sunset-primary to-sunset-secondary text-white shadow-md" : "text-black hover:bg-white/50"}`}
            >
              <div className="flex items-center gap-3">
                <ReceiptText
                  size={20} strokeWidth={2.5}
                  className={`shrink-0 transition-colors ${isTransactionsActive ? "text-white" : "text-black group-hover:text-sunset-primary"}`}
                />
                {isSidebarOpen && <span className="whitespace-nowrap">Transactions</span>}
              </div>
              {isSidebarOpen && (
                isTransactionsOpen
                  ? <ChevronUp size={14} className={isTransactionsActive ? "text-white" : "text-black/40"} />
                  : <ChevronDown size={14} className={isTransactionsActive ? "text-white" : "text-black/40"} />
              )}

              {!isSidebarOpen && (
                <div className="absolute left-full ml-4 px-3 py-2 bg-sunset-dark text-white text-sm font-medium rounded-xl opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all whitespace-nowrap z-50">
                  Transactions
                </div>
              )}
            </button>

            {isSidebarOpen && isTransactionsOpen && (
              <div className="mt-1 ml-4 pl-3 border-l-2 border-orange-200 space-y-1">
                {transactionSubItems.map((item) => (
                  <button
                    key={item.id}
                    onClick={() => router.push(item.id)}
                    className={`w-full flex items-center justify-between gap-3 px-3 py-2.5 rounded-xl font-bold transition-all duration-200 group outline-none text-sm ${isActive(item.id) ? "bg-gradient-to-br from-sunset-primary to-sunset-secondary text-white shadow-md" : "text-black hover:bg-white/50"}`}
                  >
                    <div className="flex items-center gap-2.5">
                      <item.icon
                        size={16} strokeWidth={2.5}
                        className={`shrink-0 ${isActive(item.id) ? "text-white" : "text-black group-hover:text-sunset-primary"}`}
                      />
                      <span className="whitespace-nowrap">{item.label}</span>
                    </div>
                    {isActive(item.id) && <div className="w-1.5 h-1.5 rounded-full bg-white shrink-0" />}
                  </button>
                ))}
              </div>
            )}
          </div>

        </nav>

        {/* 底部 Logout */}
        <div className="p-4 border-t border-orange-200/50 mt-auto">
          <button
            onClick={() => setIsLogoutModalOpen(true)}
            className={`w-full flex items-center gap-3 rounded-2xl font-bold text-black hover:bg-white/50 hover:text-red-500 transition-all group ${isSidebarOpen ? "px-4 py-3" : "justify-center p-3"}`}
          >
            <LogOut size={20} className="shrink-0 text-black group-hover:text-red-500 transition-colors" />
            {isSidebarOpen && <span className="whitespace-nowrap">Logout</span>}
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 flex flex-col min-h-screen overflow-hidden w-full pb-20 md:pb-0">
        <div className="flex-1 overflow-y-auto p-4 sm:p-6 md:p-8 lg:p-10">
          <div className="max-w-7xl mx-auto">
            {children}
          </div>
        </div>
      </main>

      {/* =========================================================================
          Mobile Bottom Navigation
      ========================================================================= */}
      <div className="md:hidden fixed bottom-0 left-0 right-0 h-16 bg-white border-t border-black/5 flex items-center justify-around px-2 z-50 pb-safe shadow-[0_-4px_24px_rgba(0,0,0,0.02)]">
        {mobileBottomNavItems.map((item) => {
          const isTransMenu = item.id === 'transactions_menu';
          const isSetMenu = item.id === 'settings_menu';

          const isCurrentActive = isTransMenu
            ? (isMobileTransactionsOpen || isTransactionsActive)
            : isSetMenu
            ? (isMobileMenuOpen || moreMenuPaths.some(p => safePathname === p || safePathname.startsWith(p)))
            : isActive(item.id);

          return (
            <button
              key={item.id}
              onClick={() => {
                if (isTransMenu) {
                  setIsMobileTransactionsOpen(!isMobileTransactionsOpen);
                  setIsMobileMenuOpen(false);
                } else if (isSetMenu) {
                  setIsMobileMenuOpen(!isMobileMenuOpen);
                  setIsMobileTransactionsOpen(false);
                } else {
                  router.push(item.id);
                  setIsMobileTransactionsOpen(false);
                  setIsMobileMenuOpen(false);
                }
              }}
              className={`flex flex-col items-center justify-center w-16 h-full gap-1 transition-colors ${
                isCurrentActive ? "text-orange-600" : "text-sunset-dark/50 hover:text-orange-500"
              }`}
            >
              <item.icon
                size={20}
                strokeWidth={isCurrentActive ? 2.5 : 2}
                className={isCurrentActive ? "text-orange-600 drop-shadow-sm" : ""}
              />
              <span className="text-[10px] font-bold">{item.label}</span>
            </button>
          );
        })}
      </div>

      {/* Mobile Transactions Drawer Menu */}
      {isMobileTransactionsOpen && (
        <div
          className="md:hidden fixed inset-0 bg-sunset-dark/40 backdrop-blur-sm z-40"
          onClick={() => setIsMobileTransactionsOpen(false)}
        >
          <div
            className="absolute bottom-16 right-4 left-4 sm:left-auto sm:w-72 bg-white rounded-3xl p-4 shadow-2xl border border-sunset-primary/10 animate-in slide-in-from-bottom-5"
            onClick={(e) => e.stopPropagation()}
          >
            <p className="text-[10px] font-black text-orange-500 uppercase tracking-widest px-2 pb-2">TRANSACTIONS & SETUP</p>
            
            <div className="space-y-1">
              {transactionSubItems.map((item) => (
                <button
                  key={item.id}
                  onClick={() => { router.push(item.id); setIsMobileTransactionsOpen(false); }}
                  className={`w-full flex items-center justify-between gap-3 px-4 py-2.5 rounded-2xl font-bold transition-all duration-200 group ${isActive(item.id) ? "bg-gradient-to-br from-sunset-primary to-sunset-secondary text-white shadow-md" : "text-black hover:bg-orange-50 hover:text-sunset-primary"}`}
                >
                  <div className="flex items-center gap-3">
                    <item.icon size={18} strokeWidth={isActive(item.id) ? 2.5 : 2}
                      className={`${isActive(item.id) ? "text-white" : "text-black group-hover:text-sunset-primary"}`} />
                    <span>{item.label}</span>
                  </div>
                  {isActive(item.id) && <div className="w-1.5 h-1.5 rounded-full bg-white shrink-0" />}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Mobile Settings Drawer Menu (Profile, Budget, Users, Logout) */}
      {isMobileMenuOpen && (
        <div
          className="md:hidden fixed inset-0 bg-sunset-dark/40 backdrop-blur-sm z-40"
          onClick={() => setIsMobileMenuOpen(false)}
        >
          <div
            className="absolute bottom-16 right-4 left-4 sm:left-auto sm:w-72 bg-white rounded-3xl p-4 shadow-2xl border border-sunset-primary/10 animate-in slide-in-from-bottom-5"
            onClick={(e) => e.stopPropagation()}
          >
            {/* User Info Header */}
            <div className="flex items-center gap-3 bg-gradient-to-br from-orange-50/50 to-red-50/50 p-3 rounded-2xl border border-orange-100 mb-3">
              <div className="w-10 h-10 rounded-full bg-gradient-to-br from-sunset-primary to-sunset-secondary flex items-center justify-center text-white font-bold shrink-0 shadow-sm text-lg uppercase">
                {user?.full_name ? user.full_name.charAt(0) : 'U'}
              </div>
              <div className="flex flex-col leading-tight overflow-hidden">
                <span className="font-bold text-black text-sm whitespace-nowrap truncate">{user?.full_name || 'User'}</span>
                <span className="text-[10px] font-bold text-sunset-primary uppercase tracking-widest mt-0.5">
                  {getRoleName(user?.role)}
                </span>
              </div>
            </div>

            <p className="text-[10px] font-black text-orange-500 uppercase tracking-widest px-2 pb-2">SETTINGS & ACCOUNT</p>
            
            <div className="space-y-1">
              {/* Profile */}
              <button
                onClick={() => { router.push('/profile'); setIsMobileMenuOpen(false); }}
                className={`w-full flex items-center justify-between gap-3 px-4 py-2.5 rounded-2xl font-bold transition-all duration-200 group ${isActive('/profile') ? "bg-gradient-to-br from-sunset-primary to-sunset-secondary text-white shadow-md" : "text-black hover:bg-orange-50 hover:text-sunset-primary"}`}
              >
                <div className="flex items-center gap-3">
                  <User size={18} strokeWidth={isActive('/profile') ? 2.5 : 2}
                    className={`${isActive('/profile') ? "text-white" : "text-black group-hover:text-sunset-primary"}`} />
                  <span>Profile</span>
                </div>
                {isActive('/profile') && <div className="w-1.5 h-1.5 rounded-full bg-white shrink-0" />}
              </button>

              {/* Budget */}
              <button
                onClick={() => { router.push('/budget'); setIsMobileMenuOpen(false); }}
                className={`w-full flex items-center justify-between gap-3 px-4 py-2.5 rounded-2xl font-bold transition-all duration-200 group ${isActive('/budget') ? "bg-gradient-to-br from-sunset-primary to-sunset-secondary text-white shadow-md" : "text-black hover:bg-orange-50 hover:text-sunset-primary"}`}
              >
                <div className="flex items-center gap-3">
                  <PieChart size={18} strokeWidth={isActive('/budget') ? 2.5 : 2}
                    className={`${isActive('/budget') ? "text-white" : "text-black group-hover:text-sunset-primary"}`} />
                  <span>Budget</span>
                </div>
                {isActive('/budget') && <div className="w-1.5 h-1.5 rounded-full bg-white shrink-0" />}
              </button>

              {/* Users (仅管理员) */}
              {canSeeUsers && (
                <button
                  onClick={() => { router.push('/users'); setIsMobileMenuOpen(false); }}
                  className={`w-full flex items-center justify-between gap-3 px-4 py-2.5 rounded-2xl font-bold transition-all duration-200 group ${isActive('/users') ? "bg-gradient-to-br from-sunset-primary to-sunset-secondary text-white shadow-md" : "text-black hover:bg-orange-50 hover:text-sunset-primary"}`}
                >
                  <div className="flex items-center gap-3">
                    <Users size={18} strokeWidth={isActive('/users') ? 2.5 : 2}
                      className={`${isActive('/users') ? "text-white" : "text-black group-hover:text-sunset-primary"}`} />
                    <span>Users</span>
                  </div>
                  {isActive('/users') && <div className="w-1.5 h-1.5 rounded-full bg-white shrink-0" />}
                </button>
              )}
            </div>

            <div className="my-2 border-t border-dashed border-orange-100" />
            
            {/* Logout */}
            <button
              onClick={() => { setIsMobileMenuOpen(false); setIsLogoutModalOpen(true); }}
              className="w-full flex items-center gap-3 px-4 py-2.5 rounded-2xl font-bold text-red-500 hover:bg-red-50 transition-all"
            >
              <LogOut size={18} />
              <span>Logout</span>
            </button>
          </div>
        </div>
      )}

      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}

      <Modal isOpen={isLogoutModalOpen} onClose={() => setIsLogoutModalOpen(false)} title="Confirm Logout">
        <div className="space-y-4">
          <p className="font-medium text-sunset-dark">Are you sure you want to log out of your account?</p>
          <div className="flex flex-col sm:flex-row justify-end pt-4 gap-3">
            <Button variant="ghost" onClick={() => setIsLogoutModalOpen(false)}>Cancel</Button>
            <Button variant="danger" onClick={handleLogout}>Logout</Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}