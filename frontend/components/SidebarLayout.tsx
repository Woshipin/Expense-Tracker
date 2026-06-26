"use client";
import { usePathname, useRouter } from "next/navigation";
import { cn } from "@/lib/utils";
import {
  LayoutDashboard, ReceiptText, PieChart, Settings, LogOut,
  Calendar, DollarSign, BarChart3, MoreHorizontal, ChevronLeft,
  ChevronRight, Tags, CreditCard, Users, Loader2, Layers,
  ChevronDown, ChevronUp
} from 'lucide-react';
import React, { useState, useEffect } from "react";
import { Modal, Button, Toast } from "@/components/ui";
import api from "@/lib/axios";

export default function SidebarLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [isLogoutModalOpen, setIsLogoutModalOpen] = useState(false);
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' | 'warning' } | null>(null);

  const [user, setUser] = useState<any>(null);
  const [isCheckingAuth, setIsCheckingAuth] = useState(true);

  const isAuthPage =
    pathname === "/login" ||
    pathname === "/register" ||
    pathname === "/forgot-password" ||
    pathname === "/reset-password";

  // Auto-expand Settings dropdown if currently on a settings sub-page
  const settingsSubPaths = ['/profile', '/types', '/categories', '/payment-methods'];
  const isOnSettingsPage = settingsSubPaths.some(p => pathname === p || pathname.startsWith(p));

  useEffect(() => {
    if (isOnSettingsPage) setIsSettingsOpen(true);
  }, [isOnSettingsPage]);

  useEffect(() => {
    const checkAuth = async () => {
      try {
        const response = await api.get('/me');
        setUser(response.data);
        if (isAuthPage) {
          setToast({ message: "You are already logged in. Redirecting...", type: "error" });
          setTimeout(() => { router.push('/dashboard'); }, 1500);
        } else {
          setIsCheckingAuth(false);
        }
      } catch (error) {
        setUser(null);
        if (!isAuthPage) {
          setToast({ message: "Please login to access this page.", type: "error" });
          setTimeout(() => { router.push('/login'); }, 1500);
        } else {
          setIsCheckingAuth(false);
        }
      }
    };
    checkAuth();
  }, [pathname, router, isAuthPage]);

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
      setIsLogoutModalOpen(false);
      setUser(null);
      setToast({ message: "Logout successful. Redirecting...", type: "success" });
      setTimeout(() => { router.push('/login'); }, 1500);
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

  // ============================================================
  // Navigation structure
  // ============================================================
  const mainNavItems = [
    { id: '/dashboard',   label: 'Dashboard',  icon: LayoutDashboard },
    { id: '/ai-insights', label: 'AI Insights', icon: BarChart3 },
    { id: '/users',       label: 'Users',       icon: Users },
    { id: '/calendar',    label: 'Calendar',    icon: Calendar },
    { id: '/expenses',    label: 'Expenses',    icon: ReceiptText },
    { id: '/income',      label: 'Income',      icon: DollarSign },
    { id: '/budget',      label: 'Budget',      icon: PieChart },
  ];

  const settingsSubItems = [
    { id: '/profile',          label: 'Profile',          icon: Settings },
    { id: '/types',            label: 'Types',            icon: Layers },
    { id: '/categories',       label: 'Categories',       icon: Tags },
    { id: '/payment-methods',  label: 'Payment Methods',  icon: CreditCard },
  ];

  // Mobile bottom bar — 5 most important items
  const mobileNavItems = [
    { id: '/dashboard',   label: 'Dash',      icon: LayoutDashboard },
    { id: '/expenses',    label: 'Expenses',  icon: ReceiptText },
    { id: '/income',      label: 'Income',    icon: DollarSign },
    { id: '/ai-insights', label: 'AI',        icon: BarChart3 },
    { id: '/budget',      label: 'Budget',    icon: PieChart },
  ];

  // Pages that belong to the "More" overflow menu on mobile
  const moreMenuPaths = ['/users', '/calendar', '/profile', '/types', '/categories', '/payment-methods'];

  const isActive = (id: string) =>
    pathname === id || (pathname.startsWith(id) && id !== '/');

  const isSettingsActive = settingsSubItems.some(i => isActive(i.id));

  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-50 via-red-50 to-orange-100 flex selection:bg-sunset-primary/20">

      {/* ================================================================
          Desktop Sidebar
      ================================================================ */}
      <aside className={cn(
        "hidden md:flex flex-col bg-gradient-to-b from-orange-100/90 via-orange-50/90 to-red-100/90 backdrop-blur-md shadow-[4px_0_24px_rgba(234,88,12,0.08)] border-0 transition-all duration-300 relative z-40",
        isSidebarOpen ? "w-64" : "w-20"
      )}>
        {/* Logo */}
        <div className="p-6 flex items-center gap-3 overflow-hidden">
          <div className="w-10 h-10 rounded-[12px] bg-amber-400 text-sunset-dark flex flex-shrink-0 items-center justify-center font-bold text-2xl shadow-sm tracking-tight">+</div>
          {isSidebarOpen && (
            <div className="flex flex-col items-start leading-tight">
              <span className="font-extrabold text-sunset-dark text-xl tracking-tight shrink-0 whitespace-nowrap">Sunset</span>
              <span className="text-[9px] font-bold text-sunset-dark/40 tracking-wider">EXPENSE TRACKER</span>
            </div>
          )}
        </div>

        {/* User Card */}
        <div className="px-4 mb-4 shrink-0">
          <div className={cn(
            "rounded-2xl border border-orange-300 bg-white/40 flex items-center transition-all overflow-hidden",
            isSidebarOpen ? "p-3 gap-3" : "justify-center p-2"
          )}>
            <div className="w-8 h-8 rounded-full bg-gradient-to-br from-[#f89c8a] to-red-500 flex items-center justify-center text-white font-bold shrink-0 shadow-sm uppercase">
              {user?.full_name ? user.full_name.charAt(0) : 'U'}
            </div>
            {isSidebarOpen && (
              <div className="flex flex-col leading-tight overflow-hidden">
                <span className="font-bold text-black text-sm whitespace-nowrap truncate">{user?.full_name || 'User'}</span>
                <span className="text-[10px] font-bold text-orange-600 uppercase tracking-widest mt-0.5">
                  {getRoleName(user?.role)}
                </span>
              </div>
            )}
          </div>
        </div>

        {/* Collapse toggle */}
        <button
          onClick={() => setIsSidebarOpen(!isSidebarOpen)}
          className="absolute -right-3 top-8 w-6 h-6 bg-white border border-orange-300 rounded-full flex items-center justify-center text-sunset-dark hover:text-orange-500 shadow-sm z-50"
        >
          {isSidebarOpen ? <ChevronLeft size={14} /> : <ChevronRight size={14} />}
        </button>

        {/* Nav */}
        <nav className="px-4 py-2 space-y-1 overflow-y-auto custom-scrollbar">

          {/* Main nav items */}
          {mainNavItems.map((item) => (
            <button
              key={item.id}
              onClick={() => router.push(item.id)}
              className={cn(
                "w-full flex items-center justify-between gap-3 rounded-2xl font-bold transition-all duration-200 group relative outline-none",
                isSidebarOpen ? "px-4 py-3" : "justify-center p-3",
                isActive(item.id)
                  ? "bg-gradient-to-br from-sunset-primary to-sunset-secondary text-white shadow-md"
                  : "text-black hover:bg-white/50"
              )}
            >
              <div className="flex items-center gap-3">
                <item.icon
                  size={20} strokeWidth={2.5}
                  className={cn("shrink-0 transition-colors", isActive(item.id) ? "text-white" : "text-black group-hover:text-sunset-primary")}
                />
                {isSidebarOpen && <span className="whitespace-nowrap">{item.label}</span>}
              </div>
              {isActive(item.id) && isSidebarOpen && <div className="w-1.5 h-1.5 rounded-full bg-white shrink-0" />}

              {/* Collapsed tooltip */}
              {!isSidebarOpen && (
                <div className="absolute left-full ml-4 px-3 py-2 bg-sunset-dark text-white text-sm font-medium rounded-xl opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all whitespace-nowrap z-50">
                  {item.label}
                </div>
              )}
            </button>
          ))}

          {/* Settings dropdown */}
          <div>
            <button
              onClick={() => {
                if (isSidebarOpen) {
                  setIsSettingsOpen(prev => !prev);
                } else {
                  // When collapsed, just navigate to profile
                  router.push('/profile');
                }
              }}
              className={cn(
                "w-full flex items-center justify-between gap-3 rounded-2xl font-bold transition-all duration-200 group relative outline-none",
                isSidebarOpen ? "px-4 py-3" : "justify-center p-3",
                isSettingsActive
                  ? "bg-gradient-to-br from-sunset-primary to-sunset-secondary text-white shadow-md"
                  : "text-black hover:bg-white/50"
              )}
            >
              <div className="flex items-center gap-3">
                <Settings
                  size={20} strokeWidth={2.5}
                  className={cn("shrink-0 transition-colors", isSettingsActive ? "text-white" : "text-black group-hover:text-sunset-primary")}
                />
                {isSidebarOpen && <span className="whitespace-nowrap">Settings</span>}
              </div>
              {isSidebarOpen && (
                isSettingsOpen
                  ? <ChevronUp size={14} className={isSettingsActive ? "text-white" : "text-black/40"} />
                  : <ChevronDown size={14} className={isSettingsActive ? "text-white" : "text-black/40"} />
              )}

              {!isSidebarOpen && (
                <div className="absolute left-full ml-4 px-3 py-2 bg-sunset-dark text-white text-sm font-medium rounded-xl opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all whitespace-nowrap z-50">
                  Settings
                </div>
              )}
            </button>

            {/* Sub-items */}
            {isSidebarOpen && isSettingsOpen && (
              <div className="mt-1 ml-4 pl-3 border-l-2 border-orange-200 space-y-1">
                {settingsSubItems.map((item) => (
                  <button
                    key={item.id}
                    onClick={() => router.push(item.id)}
                    className={cn(
                      "w-full flex items-center justify-between gap-3 px-3 py-2.5 rounded-xl font-bold transition-all duration-200 group outline-none text-sm",
                      isActive(item.id)
                        ? "bg-gradient-to-br from-sunset-primary to-sunset-secondary text-white shadow-md"
                        : "text-black hover:bg-white/50"
                    )}
                  >
                    <div className="flex items-center gap-2.5">
                      <item.icon
                        size={16} strokeWidth={2.5}
                        className={cn("shrink-0", isActive(item.id) ? "text-white" : "text-black group-hover:text-sunset-primary")}
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

        {/* Logout */}
        <div className="p-4 border-t border-orange-200/50">
          <button
            onClick={() => setIsLogoutModalOpen(true)}
            className={cn(
              "w-full flex items-center gap-3 rounded-2xl font-bold text-black hover:bg-white/50 hover:text-red-500 transition-all group",
              isSidebarOpen ? "px-4 py-3" : "justify-center p-3"
            )}
          >
            <LogOut size={20} className="shrink-0 text-black group-hover:text-red-500 transition-colors" />
            {isSidebarOpen && <span className="whitespace-nowrap">Logout</span>}
          </button>
        </div>
      </aside>

      {/* ================================================================
          Main Content — fix: remove fixed height, use flex-1 + overflow
      ================================================================ */}
      <main className="flex-1 flex flex-col min-h-screen overflow-hidden w-full pb-20 md:pb-0">
        <div className="flex-1 overflow-y-auto p-4 sm:p-6 md:p-8 lg:p-10">
          <div className="max-w-7xl mx-auto">
            {children}
          </div>
        </div>
      </main>

      {/* ================================================================
          Mobile Bottom Navigation Bar
      ================================================================ */}
      <div className="md:hidden fixed bottom-0 left-0 right-0 h-16 bg-white border-t border-black/5 flex items-center justify-around px-2 z-50 pb-safe shadow-[0_-4px_24px_rgba(0,0,0,0.02)]">
        {mobileNavItems.map((item) => (
          <button
            key={item.id}
            onClick={() => router.push(item.id)}
            className={cn(
              "flex flex-col items-center justify-center w-16 h-full gap-1 transition-colors",
              isActive(item.id) ? "text-orange-600" : "text-sunset-dark/50 hover:text-orange-500"
            )}
          >
            <item.icon
              size={20}
              strokeWidth={isActive(item.id) ? 2.5 : 2}
              className={cn(isActive(item.id) ? "text-orange-600 drop-shadow-sm" : "")}
            />
            <span className="text-[10px] font-bold">{item.label}</span>
          </button>
        ))}

        {/* More button */}
        <button
          onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
          className={cn(
            "flex flex-col items-center justify-center w-16 h-full gap-1 transition-colors",
            isMobileMenuOpen || moreMenuPaths.some(p => pathname === p || pathname.startsWith(p))
              ? "text-orange-600"
              : "text-sunset-dark/50 hover:text-orange-500"
          )}
        >
          <MoreHorizontal
            size={20}
            strokeWidth={isMobileMenuOpen || moreMenuPaths.some(p => pathname === p || pathname.startsWith(p)) ? 2.5 : 2}
          />
          <span className="text-[10px] font-bold">More</span>
        </button>
      </div>

      {/* ================================================================
          Mobile More Menu Overlay
      ================================================================ */}
      {isMobileMenuOpen && (
        <div
          className="md:hidden fixed inset-0 bg-sunset-dark/40 backdrop-blur-sm z-40"
          onClick={() => setIsMobileMenuOpen(false)}
        >
          <div
            className="absolute bottom-16 right-4 w-64 bg-white rounded-3xl p-3 shadow-2xl border border-sunset-primary/10 animate-in slide-in-from-bottom-5"
            onClick={(e) => e.stopPropagation()}
          >
            {/* User info */}
            <div className="flex items-center gap-3 bg-gradient-to-br from-orange-50/50 to-red-50/50 p-3 rounded-2xl border border-orange-100 mb-2">
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

            {/* More menu items: Calendar + Users */}
            {[
              { id: '/users',    label: 'Users',    icon: Users },
              { id: '/calendar', label: 'Calendar', icon: Calendar },
            ].map((item) => (
              <button
                key={item.id}
                onClick={() => { router.push(item.id); setIsMobileMenuOpen(false); }}
                className={cn(
                  "w-full flex items-center justify-between gap-3 px-4 py-3 rounded-2xl font-bold transition-all duration-200 group",
                  isActive(item.id)
                    ? "bg-gradient-to-br from-sunset-primary to-sunset-secondary text-white shadow-md"
                    : "text-black hover:bg-orange-50 hover:text-sunset-primary"
                )}
              >
                <div className="flex items-center gap-3">
                  <item.icon size={18} strokeWidth={isActive(item.id) ? 2.5 : 2}
                    className={cn(isActive(item.id) ? "text-white" : "text-black group-hover:text-sunset-primary")} />
                  <span>{item.label}</span>
                </div>
                {isActive(item.id) && <div className="w-1.5 h-1.5 rounded-full bg-white shrink-0" />}
              </button>
            ))}

            {/* Settings section divider */}
            <div className="my-1.5 mx-2 border-t border-dashed border-orange-100" />
            <p className="text-[10px] font-black text-orange-400 uppercase tracking-widest px-4 pb-1">Settings</p>

            {settingsSubItems.map((item) => (
              <button
                key={item.id}
                onClick={() => { router.push(item.id); setIsMobileMenuOpen(false); }}
                className={cn(
                  "w-full flex items-center justify-between gap-3 px-4 py-3 rounded-2xl font-bold transition-all duration-200 group",
                  isActive(item.id)
                    ? "bg-gradient-to-br from-sunset-primary to-sunset-secondary text-white shadow-md"
                    : "text-black hover:bg-orange-50 hover:text-sunset-primary"
                )}
              >
                <div className="flex items-center gap-3">
                  <item.icon size={18} strokeWidth={isActive(item.id) ? 2.5 : 2}
                    className={cn(isActive(item.id) ? "text-white" : "text-black group-hover:text-sunset-primary")} />
                  <span>{item.label}</span>
                </div>
                {isActive(item.id) && <div className="w-1.5 h-1.5 rounded-full bg-white shrink-0" />}
              </button>
            ))}

            {/* Logout */}
            <div className="my-1 border-t border-sunset-primary/5" />
            <button
              onClick={() => { setIsMobileMenuOpen(false); setIsLogoutModalOpen(true); }}
              className="w-full flex items-center gap-3 px-4 py-3 rounded-2xl font-semibold text-red-500 hover:bg-red-50 transition-all"
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