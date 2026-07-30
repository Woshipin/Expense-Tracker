"use client";

import React, { useState, useEffect, useMemo } from "react";
import { useRouter } from "next/navigation";
import { Card, Button, Input, Toast } from "@/components/ui";
import {
  Search,
  Plus,
  Edit2,
  Trash2,
  ShieldCheck,
  Users,
  Lock,
  CheckSquare,
  Square,
  Loader2,
  X,
  ChevronDown,
  ChevronUp,
  RefreshCw,
  Check,
  UserCheck,
  Shield,
  Layers,
  ShieldAlert,
} from "lucide-react";
import api from "@/lib/axios";
import { usePermission } from "@/hooks/usePermission";

interface PermissionNode {
  id: string;
  label: string;
  isAccessNode?: boolean;
}

interface PermissionModule {
  moduleKey: string;
  moduleName: string;
  accessPermissionId: string;
  permissions: PermissionNode[];
}

// 🌟 全系统模块完全统一：Access Page + Create + Edit + Delete
const SYSTEM_PERMISSION_MODULES: PermissionModule[] = [
  {
    moduleKey: "categories",
    moduleName: "Categories (分类配置页面)",
    accessPermissionId: "categories.view",
    permissions: [
      { id: "categories.view", label: "Access Page", isAccessNode: true },
      { id: "categories.create", label: "Create" },
      { id: "categories.edit", label: "Edit" },
      { id: "categories.delete", label: "Delete" },
    ],
  },
  {
    moduleKey: "payment_methods",
    moduleName: "Payment Methods (支付渠道页面)",
    accessPermissionId: "payment_methods.view",
    permissions: [
      { id: "payment_methods.view", label: "Access Page", isAccessNode: true },
      { id: "payment_methods.create", label: "Create" },
      { id: "payment_methods.edit", label: "Edit" },
      { id: "payment_methods.delete", label: "Delete" },
    ],
  },
  {
    moduleKey: "expenses",
    moduleName: "Expenses (支出管理页面)",
    accessPermissionId: "expenses.view",
    permissions: [
      { id: "expenses.view", label: "Access Page", isAccessNode: true },
      { id: "expenses.create", label: "Create" },
      { id: "expenses.edit", label: "Edit" },
      { id: "expenses.delete", label: "Delete" },
      { id: "expenses.scan", label: "Scan AI Receipt" },
    ],
  },
  {
    moduleKey: "incomes",
    moduleName: "Income (收入管理页面)",
    accessPermissionId: "incomes.view",
    permissions: [
      { id: "incomes.view", label: "Access Page", isAccessNode: true },
      { id: "incomes.create", label: "Create" },
      { id: "incomes.edit", label: "Edit" },
      { id: "incomes.delete", label: "Delete" },
    ],
  },
  {
    moduleKey: "types",
    moduleName: "Types (交易类型页面)",
    accessPermissionId: "types.view",
    permissions: [
      { id: "types.view", label: "Access Page", isAccessNode: true },
      { id: "types.create", label: "Create" },
      { id: "types.edit", label: "Edit" },
      { id: "types.delete", label: "Delete" },
    ],
  },
  {
    moduleKey: "budget",
    moduleName: "Budget (预算中心页面)",
    accessPermissionId: "budget.view",
    permissions: [
      { id: "budget.view", label: "Access Page", isAccessNode: true },
      { id: "budget.create", label: "Create" },
      { id: "budget.edit", label: "Edit" },
      { id: "budget.delete", label: "Delete" },
    ],
  },
  {
    moduleKey: "calendar",
    moduleName: "Calendar (日历流页面)",
    accessPermissionId: "calendar.view",
    permissions: [
      { id: "calendar.view", label: "Access Page", isAccessNode: true },
      { id: "calendar.create", label: "Create" },
      { id: "calendar.edit", label: "Edit" },
      { id: "calendar.delete", label: "Delete" },
    ],
  },
  {
    moduleKey: "users",
    moduleName: "Users (用户管理页面)",
    accessPermissionId: "users.view",
    permissions: [
      { id: "users.view", label: "Access Page", isAccessNode: true },
      { id: "users.create", label: "Create User" },
      { id: "users.edit", label: "Edit User" },
      { id: "users.delete", label: "Delete User" },
    ],
  },
  {
    moduleKey: "dashboard",
    moduleName: "Dashboard (仪表盘页面)",
    accessPermissionId: "dashboard.view",
    permissions: [
      { id: "dashboard.view", label: "Access Page", isAccessNode: true },
    ],
  },
  {
    moduleKey: "ai_insights",
    moduleName: "AI Insights (AI 智能分析页面)",
    accessPermissionId: "ai_insights.view",
    permissions: [
      { id: "ai_insights.view", label: "Access Page", isAccessNode: true },
      { id: "ai_insights.chat", label: "AI Chatbot" }, // 🌟 包含 Chatbot 独立对话勾选项
    ],
  },
  {
    moduleKey: "permissions",
    moduleName: "Permission Groups (权限设置页面)",
    accessPermissionId: "permissions.view",
    permissions: [
      { id: "permissions.view", label: "Access Page", isAccessNode: true },
      { id: "permissions.manage", label: "Manage Groups" },
    ],
  },
];

const ROLES_CONFIG = [
  { roleId: 0, label: "Super Admin", badgeBg: "bg-purple-50 text-purple-600 border-purple-200" },
  { roleId: 1, label: "Admin", badgeBg: "bg-indigo-50 text-indigo-600 border-indigo-200" },
  { roleId: 2, label: "Premium User", badgeBg: "bg-amber-50 text-amber-600 border-amber-200" },
  { roleId: 3, label: "Basic User", badgeBg: "bg-slate-100 text-slate-600 border-slate-200" },
];

export default function PermissionGroupsPage() {
  const router = useRouter();
  const { can, isLoading: isAuthChecking } = usePermission();

  const [groups, setGroups] = useState<any[]>([]);
  const [allUsers, setAllUsers] = useState<any[]>([]);
  const [toast, setToast] = useState<{ message: string; type: "success" | "error" | "warning" } | null>(null);

  // Modals state
  const [isAddEditOpen, setIsAddEditOpen] = useState(false);
  const [viewingGroup, setViewingGroup] = useState<any>(null);
  const [editingGroup, setEditingGroup] = useState<any>(null);
  const [deletingGroup, setDeletingGroup] = useState<any>(null);

  const [activeModalTab, setActiveModalTab] = useState<"permissions" | "members">("permissions");

  // Search & Filter
  const [searchQuery, setSearchQuery] = useState("");
  const [userSearchQuery, setUserSearchQuery] = useState("");

  const [collapsedRoles, setCollapsedRoles] = useState<Record<number, boolean>>({});

  // Loading States
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);

  // Form Fields State
  const [formData, setFormData] = useState({
    name: "",
    description: "",
    permissions: [] as string[],
    assigned_user_ids: [] as number[],
  });
  const [errors, setErrors] = useState<any>({});

  const showToast = (message: string, type: "success" | "error" | "warning" = "success") => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  const hasAccessPermission = can("permissions.view");

  useEffect(() => {
    if (!isAuthChecking && !hasAccessPermission) {
      showToast("Access Denied: Permission Management rights required.", "error");
      setTimeout(() => {
        router.replace("/dashboard");
      }, 1500);
    }
  }, [isAuthChecking, hasAccessPermission, router]);

  const fetchAllUsers = async () => {
    try {
      const res = await api.get("/users", { params: { limit: 500 } });
      const list = res.data?.data || res.data || [];
      setAllUsers(list);
    } catch (e) {
      console.error("Failed to load users for group assignment", e);
    }
  };

  const fetchGroups = async () => {
    if (!hasAccessPermission) return;
    setIsLoading(true);
    try {
      const res = await api.get("/permission-groups", { params: { search: searchQuery } });
      const groupData = res.data?.data || res.data || [];
      setGroups(groupData);
    } catch (e) {
      console.error("Failed to load permission groups from backend API", e);
      showToast("Failed to fetch permission groups.", "error");
      setGroups([]);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    if (hasAccessPermission) {
      fetchAllUsers();
      fetchGroups();
    }
  }, [hasAccessPermission]);

  useEffect(() => {
    if (!hasAccessPermission) return;
    const delayDebounce = setTimeout(() => {
      fetchGroups();
    }, 400);
    return () => clearTimeout(delayDebounce);
  }, [searchQuery, hasAccessPermission]);

  const openAddModal = () => {
    setErrors({});
    setActiveModalTab("permissions");
    setUserSearchQuery("");
    setFormData({
      name: "",
      description: "",
      permissions: ["categories.view", "payment_methods.view"],
      assigned_user_ids: [],
    });
    setIsAddEditOpen(true);
  };

  const openEditModal = (g: any) => {
    setErrors({});
    setActiveModalTab("permissions");
    setUserSearchQuery("");

    const existingUserIds = g.users ? g.users.map((u: any) => Number(u.id)) : [];

    setFormData({
      name: g.name || "",
      description: g.description || "",
      permissions: g.permissions || [],
      assigned_user_ids: existingUserIds,
    });
    setEditingGroup(g);
    setIsAddEditOpen(true);
  };

  const handleSaveGroup = async () => {
    if (!formData.name.trim()) {
      setErrors({ name: ["Group name is required."] });
      return;
    }

    setIsSaving(true);
    setErrors({});

    try {
      if (editingGroup) {
        await api.put(`/permission-groups/${editingGroup.id}`, formData);
        showToast("Permission group updated successfully!", "success");
      } else {
        await api.post("/permission-groups", formData);
        showToast("Permission group created successfully!", "success");
      }

      window.dispatchEvent(new Event("permissions-updated"));

      setIsAddEditOpen(false);
      setEditingGroup(null);
      fetchGroups();
    } catch (error: any) {
      if (error.response && error.response.status === 422) {
        setErrors(error.response.data.errors);
      } else {
        showToast(error.response?.data?.message || "Operation failed.", "error");
      }
    } finally {
      setIsSaving(false);
    }
  };

  const handleDeleteGroup = async () => {
    if (!deletingGroup) return;
    try {
      await api.delete(`/permission-groups/${deletingGroup.id}`);
      showToast("Permission group deleted successfully", "success");

      window.dispatchEvent(new Event("permissions-updated"));

      setDeletingGroup(null);
      fetchGroups();
    } catch (error: any) {
      showToast(error.response?.data?.message || "Failed to delete group", "error");
      setDeletingGroup(null);
    }
  };

  const togglePermission = (module: PermissionModule, permId: string, isAccessNode?: boolean) => {
    setFormData((prev) => {
      const exists = prev.permissions.includes(permId);
      let newPerms: string[];

      if (isAccessNode && exists) {
        const modulePermIds = module.permissions.map((p) => p.id);
        newPerms = prev.permissions.filter((p) => !modulePermIds.includes(p));
      } else {
        newPerms = exists
          ? prev.permissions.filter((p) => p !== permId)
          : [...prev.permissions, permId];
      }

      return { ...prev, permissions: newPerms };
    });
  };

  const toggleModuleAllPermissions = (module: PermissionModule) => {
    const modulePermIds = module.permissions.map((p) => p.id);
    const isAllSelected = modulePermIds.every((id) => formData.permissions.includes(id));

    setFormData((prev) => {
      let updated: string[];
      if (isAllSelected) {
        updated = prev.permissions.filter((id) => !modulePermIds.includes(id));
      } else {
        const set = new Set([...prev.permissions, ...modulePermIds]);
        updated = Array.from(set);
      }
      return { ...prev, permissions: updated };
    });
  };

  const groupedUsersByRole = useMemo(() => {
    return ROLES_CONFIG.map((roleObj) => {
      const usersInRole = allUsers.filter((u) => {
        const matchesRole = Number(u.role) === roleObj.roleId;
        const matchesSearch = userSearchQuery
          ? u.full_name?.toLowerCase().includes(userSearchQuery.toLowerCase()) ||
            u.email?.toLowerCase().includes(userSearchQuery.toLowerCase())
          : true;
        return matchesRole && matchesSearch;
      });

      const selectedCount = usersInRole.filter((u) => formData.assigned_user_ids.includes(Number(u.id))).length;

      return {
        ...roleObj,
        users: usersInRole,
        selectedCount,
        isAllRoleSelected: usersInRole.length > 0 && selectedCount === usersInRole.length,
      };
    });
  }, [allUsers, userSearchQuery, formData.assigned_user_ids]);

  const toggleUserSelection = (userId: number) => {
    setFormData((prev) => {
      const exists = prev.assigned_user_ids.includes(userId);
      const updated = exists
        ? prev.assigned_user_ids.filter((id) => id !== userId)
        : [...prev.assigned_user_ids, userId];
      return { ...prev, assigned_user_ids: updated };
    });
  };

  const toggleRoleAllUsers = (roleUsers: any[]) => {
    const userIdsInRole = roleUsers.map((u) => Number(u.id));
    const isAllSelected = userIdsInRole.every((id) => formData.assigned_user_ids.includes(id));

    setFormData((prev) => {
      let updated: number[];
      if (isAllSelected) {
        updated = prev.assigned_user_ids.filter((id) => !userIdsInRole.includes(id));
      } else {
        const set = new Set([...prev.assigned_user_ids, ...userIdsInRole]);
        updated = Array.from(set);
      }
      return { ...prev, assigned_user_ids: updated };
    });
  };

  if (isAuthChecking) {
    return (
      <div className="text-center py-20">
        <Loader2 className="animate-spin text-orange-500 mx-auto w-10 h-10" />
      </div>
    );
  }

  if (!hasAccessPermission) {
    return (
      <div className="min-h-[60vh] flex items-center justify-center p-4">
        <Card className="max-w-md w-full p-8 text-center bg-white rounded-3xl shadow-xl border border-red-100 flex flex-col items-center gap-4">
          <div className="w-16 h-16 bg-red-100 text-red-500 rounded-2xl flex items-center justify-center">
            <ShieldAlert size={36} />
          </div>
          <div>
            <h2 className="text-xl font-extrabold text-sunset-dark">403 - Access Denied</h2>
            <p className="text-xs text-sunset-dark/60 font-medium mt-1">
              You do not have permission to view or manage permission groups. Redirecting...
            </p>
          </div>
          <Button
            onClick={() => router.replace("/dashboard")}
            className="w-full mt-2 bg-orange-500 hover:bg-orange-600 text-white font-bold"
          >
            Back to Dashboard
          </Button>
        </Card>
      </div>
    );
  }

  return (
    <>
      {toast && (
        <div className="fixed top-4 right-4 z-[10000]">
          <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />
        </div>
      )}

      {/* 1. View Group Modal */}
      {viewingGroup && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center p-3 sm:p-6 pb-20 md:pb-6 bg-sunset-dark/40 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white w-full max-w-2xl xl:max-w-4xl rounded-3xl sm:rounded-[2rem] shadow-2xl flex flex-col max-h-[calc(100vh-110px)] sm:max-h-[95vh] animate-in zoom-in-95 duration-200 overflow-hidden">
            <div className="px-6 sm:px-8 py-5 border-b border-orange-500/10 flex justify-between items-center shrink-0 bg-gray-50/50">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-2xl bg-orange-500/10 text-orange-600 flex items-center justify-center shrink-0">
                  <ShieldCheck size={22} />
                </div>
                <div>
                  <h2 className="text-xl sm:text-2xl font-black text-sunset-dark">Group Details</h2>
                  <p className="text-xs text-gray-400 font-medium">Detailed breakdown of granted access & members</p>
                </div>
              </div>
              <button
                onClick={() => setViewingGroup(null)}
                className="p-2 hover:bg-gray-100 rounded-full text-gray-400 hover:text-gray-600 transition-colors"
              >
                <X size={20} />
              </button>
            </div>

            <div className="p-6 sm:p-8 overflow-y-auto custom-scrollbar flex-1 space-y-6">
              <div className="bg-gradient-to-br from-orange-500 to-red-500 rounded-2xl p-6 text-white shadow-lg relative overflow-hidden">
                <div className="relative z-10">
                  <span className="text-[10px] font-black uppercase tracking-widest bg-white/20 px-3 py-1 rounded-lg backdrop-blur-sm inline-block mb-2">
                    Permission Group
                  </span>
                  <h3 className="text-2xl font-black">{viewingGroup.name}</h3>
                  <p className="text-xs text-white/80 font-medium mt-1">
                    {viewingGroup.description || "No description provided."}
                  </p>

                  <div className="mt-4 flex items-center gap-3 text-xs font-bold">
                    <span className="bg-white/20 backdrop-blur-md px-3.5 py-1.5 rounded-xl border border-white/20 flex items-center gap-1.5">
                      <Lock size={14} /> {viewingGroup.permissions?.length || 0} Rights Granted
                    </span>
                    <span className="bg-white/20 backdrop-blur-md px-3.5 py-1.5 rounded-xl border border-white/20 flex items-center gap-1.5">
                      <Users size={14} /> {viewingGroup.users?.length || 0} Assigned Members
                    </span>
                  </div>
                </div>
              </div>

              <div>
                <h4 className="text-xs font-black uppercase tracking-widest text-sunset-dark/50 mb-3 pl-1">
                  Active Module & Function Access
                </h4>

                <div className="space-y-3">
                  {SYSTEM_PERMISSION_MODULES.map((module) => {
                    const activePermsInModule = module.permissions.filter((p) =>
                      viewingGroup.permissions?.includes(p.id)
                    );

                    if (activePermsInModule.length === 0) return null;

                    return (
                      <div
                        key={module.moduleKey}
                        className="p-4 bg-slate-50/80 rounded-2xl border border-slate-200/80 flex flex-col gap-3"
                      >
                        <div className="flex items-center justify-between border-b border-slate-200/60 pb-2">
                          <span className="font-extrabold text-sunset-dark text-sm flex items-center gap-2">
                            <Layers size={16} className="text-orange-500" />
                            {module.moduleName}
                          </span>
                          <span className="text-[10px] font-extrabold bg-emerald-100 text-emerald-700 px-2.5 py-0.5 rounded-md uppercase tracking-wider">
                            {activePermsInModule.length} Functions Active
                          </span>
                        </div>

                        <div className="flex flex-wrap gap-2">
                          {activePermsInModule.map((p) => (
                            <span
                              key={p.id}
                              className={`px-3 py-1.5 rounded-xl text-xs font-bold border flex items-center gap-1.5 shadow-sm ${
                                p.isAccessNode
                                  ? "bg-orange-500 text-white border-orange-600"
                                  : "bg-emerald-50 text-emerald-800 border-emerald-200/80"
                              }`}
                            >
                              <Check size={13} strokeWidth={3} /> {p.label}
                            </span>
                          ))}
                        </div>
                      </div>
                    );
                  })}

                  {(!viewingGroup.permissions || viewingGroup.permissions.length === 0) && (
                    <div className="p-8 text-center bg-gray-50 rounded-2xl border border-dashed text-gray-400 text-xs font-medium">
                      No active permissions assigned to this group.
                    </div>
                  )}
                </div>
              </div>

              <div>
                <h4 className="text-xs font-black uppercase tracking-widest text-sunset-dark/50 mb-3 pl-1">
                  Group Members ({viewingGroup.users?.length || 0})
                </h4>

                <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3">
                  {viewingGroup.users && viewingGroup.users.length > 0 ? (
                    viewingGroup.users.map((u: any) => (
                      <div
                        key={u.id}
                        className="p-3 bg-white border border-gray-200/80 rounded-2xl flex items-center gap-3 shadow-sm hover:border-orange-200 transition-colors"
                      >
                        <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-orange-400 to-red-500 text-white font-black flex items-center justify-center text-sm uppercase shrink-0 shadow-sm">
                          {u.full_name?.charAt(0) || "U"}
                        </div>
                        <div className="min-w-0 flex-1">
                          <p className="text-xs font-extrabold text-sunset-dark truncate">{u.full_name}</p>
                          <p className="text-[10px] font-medium text-gray-400 truncate">{u.email}</p>
                        </div>
                      </div>
                    ))
                  ) : (
                    <p className="text-xs text-gray-400 italic pl-1 col-span-full py-4 text-center bg-gray-50 rounded-2xl border border-dashed">
                      No members assigned to this group.
                    </p>
                  )}
                </div>
              </div>
            </div>

            <div className="px-6 sm:px-8 py-4 border-t border-orange-500/10 flex justify-end shrink-0 bg-gray-50/50">
              <Button
                onClick={() => setViewingGroup(null)}
                className="w-full sm:w-auto px-8 shadow-sm bg-orange-500 hover:bg-orange-600 text-white font-bold"
              >
                Close Window
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* 2. Add / Edit Group Modal */}
      {(isAddEditOpen || editingGroup) && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center p-3 sm:p-6 pb-20 md:pb-6 bg-sunset-dark/40 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white w-full max-w-3xl xl:max-w-4xl rounded-3xl sm:rounded-[2rem] shadow-2xl flex flex-col max-h-[calc(100vh-110px)] sm:max-h-[95vh] animate-in zoom-in-95 duration-200 overflow-hidden">
            
            <div className="px-5 sm:px-8 py-4 sm:py-5 border-b border-orange-500/10 flex justify-between items-center shrink-0">
              <div>
                <h2 className="text-xl sm:text-2xl font-bold text-sunset-dark">
                  {editingGroup ? "Edit Permission Group" : "Create Permission Group"}
                </h2>
                <p className="text-xs text-sunset-dark/60 font-medium mt-0.5">
                  Configure group name, access permissions, and assign users.
                </p>
              </div>
              <button
                onClick={() => {
                  setIsAddEditOpen(false);
                  setEditingGroup(null);
                }}
                className="p-2 bg-gray-50 hover:bg-gray-100 rounded-full text-gray-500 transition-colors"
              >
                <X size={20} />
              </button>
            </div>

            <div className="px-5 sm:px-8 pt-3 bg-slate-50/80 border-b border-gray-200 flex gap-2 shrink-0">
              <button
                onClick={() => setActiveModalTab("permissions")}
                className={`px-5 py-3 text-xs sm:text-sm font-extrabold rounded-t-2xl border-b-2 transition-all flex items-center gap-2 ${
                  activeModalTab === "permissions"
                    ? "bg-white text-orange-600 border-orange-500 shadow-sm"
                    : "text-gray-500 hover:text-sunset-dark border-transparent"
                }`}
              >
                <Lock size={16} /> 1. Permissions Matrix ({formData.permissions.length})
              </button>
              <button
                onClick={() => setActiveModalTab("members")}
                className={`px-5 py-3 text-xs sm:text-sm font-extrabold rounded-t-2xl border-b-2 transition-all flex items-center gap-2 ${
                  activeModalTab === "members"
                    ? "bg-white text-orange-600 border-orange-500 shadow-sm"
                    : "text-gray-500 hover:text-sunset-dark border-transparent"
                }`}
              >
                <UserCheck size={16} /> 2. Assign Members ({formData.assigned_user_ids.length})
              </button>
            </div>

            <div className="p-5 sm:p-8 overflow-y-auto custom-scrollbar flex-1 space-y-6">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="text-xs font-extrabold text-sunset-dark/70 tracking-widest pl-1 mb-1 block">
                    Group Name
                  </label>
                  <Input
                    placeholder="E.g. Finance Auditor"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    className="h-11 text-sm bg-white"
                  />
                  {errors.name && <p className="text-xs text-red-500 mt-1 pl-1">{errors.name[0]}</p>}
                </div>

                <div>
                  <label className="text-xs font-extrabold text-sunset-dark/70 tracking-widest pl-1 mb-1 block">
                    Description (Optional)
                  </label>
                  <Input
                    placeholder="Brief summary of what this group can access..."
                    value={formData.description}
                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                    className="h-11 text-sm bg-white"
                  />
                </div>
              </div>

              {activeModalTab === "permissions" && (
                <div className="space-y-6 animate-in fade-in duration-200">
                  <div className="flex items-center justify-between border-b border-gray-100 pb-2">
                    <h3 className="text-xs font-black text-sunset-dark/60 uppercase tracking-widest">
                      Module Access & Function Matrix
                    </h3>
                  </div>

                  <div className="space-y-4">
                    {SYSTEM_PERMISSION_MODULES.map((module) => {
                      const modulePermIds = module.permissions.map((p) => p.id);
                      const isModuleFullyChecked = modulePermIds.every((id) => formData.permissions.includes(id));
                      const isAccessPageChecked = formData.permissions.includes(module.accessPermissionId);

                      return (
                        <div
                          key={module.moduleKey}
                          className="bg-slate-50/80 rounded-2xl border border-slate-200 p-4 sm:p-5 hover:border-orange-300 transition-all shadow-sm"
                        >
                          <div className="flex items-center justify-between pb-3 border-b border-slate-200/80 mb-4">
                            <h4 className="font-extrabold text-sunset-dark text-sm sm:text-base flex items-center gap-2">
                              <Layers size={18} className="text-orange-500 shrink-0" />
                              {module.moduleName}
                            </h4>

                            <label
                              onClick={() => toggleModuleAllPermissions(module)}
                              className="flex items-center gap-2 text-xs font-bold text-orange-600 hover:text-orange-700 cursor-pointer bg-white px-3 py-1.5 rounded-xl border border-orange-200 shadow-sm transition-all active:scale-95 select-none"
                            >
                              {isModuleFullyChecked ? (
                                <CheckSquare size={16} className="text-orange-500 shrink-0" />
                              ) : (
                                <Square size={16} className="text-gray-300 shrink-0" />
                              )}
                              <span>Select All</span>
                            </label>
                          </div>

                          <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-5 gap-3">
                            {module.permissions.map((p) => {
                              const isChecked = formData.permissions.includes(p.id);
                              const isSubNodeDisabled = !p.isAccessNode && !isAccessPageChecked;

                              if (isSubNodeDisabled) {
                                return null;
                              }

                              return (
                                <label
                                  key={p.id}
                                  onClick={() => togglePermission(module, p.id, p.isAccessNode)}
                                  className={`p-3 rounded-xl border flex items-center gap-2.5 cursor-pointer transition-all select-none ${
                                    isChecked
                                      ? p.isAccessNode
                                        ? "bg-orange-500 border-orange-600 shadow-sm text-white font-extrabold"
                                        : "bg-orange-50/90 border-orange-300 shadow-sm text-orange-900 font-extrabold"
                                      : "bg-white border-gray-200/90 text-sunset-dark hover:bg-gray-50 font-medium"
                                  }`}
                                >
                                  <div className="shrink-0">
                                    {isChecked ? (
                                      <CheckSquare className={p.isAccessNode ? "text-white" : "text-orange-500"} size={18} />
                                    ) : (
                                      <Square className="text-gray-300" size={18} />
                                    )}
                                  </div>
                                  <span className="text-xs">{p.label}</span>
                                </label>
                              );
                            })}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

              {activeModalTab === "members" && (
                <div className="space-y-5 animate-in fade-in duration-200">
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-gray-100 pb-3">
                    <h3 className="text-xs font-black text-sunset-dark/60 uppercase tracking-widest">
                      Select Users to Assign
                    </h3>

                    <div className="relative w-full sm:w-64">
                      <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={16} />
                      <Input
                        placeholder="Search user name or email..."
                        value={userSearchQuery}
                        onChange={(e) => setUserSearchQuery(e.target.value)}
                        className="pl-9 h-9 text-xs bg-white rounded-xl"
                      />
                      {userSearchQuery && (
                        <button
                          onClick={() => setUserSearchQuery("")}
                          className="absolute right-2.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-red-500"
                        >
                          <X size={14} />
                        </button>
                      )}
                    </div>
                  </div>

                  <div className="space-y-4">
                    {groupedUsersByRole.map((roleGroup) => {
                      const isCollapsed = collapsedRoles[roleGroup.roleId] || false;

                      return (
                        <div
                          key={roleGroup.roleId}
                          className="bg-slate-50/80 border border-slate-200/80 rounded-2xl overflow-hidden"
                        >
                          <div className="p-3.5 bg-slate-100/80 border-b border-slate-200 flex items-center justify-between gap-3">
                            <div className="flex items-center gap-2">
                              <button
                                type="button"
                                onClick={() =>
                                  setCollapsedRoles((prev) => ({ ...prev, [roleGroup.roleId]: !prev[roleGroup.roleId] }))
                                }
                                className="p-1 hover:bg-slate-200 rounded-lg text-slate-500 transition-colors"
                              >
                                {isCollapsed ? <ChevronDown size={16} /> : <ChevronUp size={16} />}
                              </button>
                              <span className={`px-2.5 py-1 rounded-lg text-xs font-extrabold border ${roleGroup.badgeBg}`}>
                                {roleGroup.label}
                              </span>
                              <span className="text-xs font-bold text-slate-500">
                                ({roleGroup.selectedCount} / {roleGroup.users.length} selected)
                              </span>
                            </div>

                            {roleGroup.users.length > 0 && (
                              <button
                                type="button"
                                onClick={() => toggleRoleAllUsers(roleGroup.users)}
                                className={`text-xs font-bold px-3 py-1 rounded-lg border transition-all ${
                                  roleGroup.isAllRoleSelected
                                    ? "bg-orange-500 text-white border-orange-500 shadow-sm"
                                    : "bg-white text-gray-700 border-gray-200 hover:bg-orange-50"
                                }`}
                              >
                                {roleGroup.isAllRoleSelected ? "Deselect Role All" : `Select All ${roleGroup.label}s`}
                              </button>
                            )}
                          </div>

                          {!isCollapsed && (
                            <div className="p-4">
                              {roleGroup.users.length > 0 ? (
                                <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3">
                                  {roleGroup.users.map((u) => {
                                    const isUserSelected = formData.assigned_user_ids.includes(Number(u.id));

                                    return (
                                      <div
                                        key={u.id}
                                        onClick={() => toggleUserSelection(Number(u.id))}
                                        className={`p-3 rounded-xl border flex items-center gap-3 cursor-pointer transition-all select-none ${
                                          isUserSelected
                                            ? "bg-orange-50 border-orange-300 shadow-sm"
                                            : "bg-white border-gray-200/80 hover:bg-gray-50"
                                        }`}
                                      >
                                        <div className="shrink-0">
                                          {isUserSelected ? (
                                            <CheckSquare className="text-orange-500" size={18} />
                                          ) : (
                                            <Square className="text-gray-300" size={18} />
                                          )}
                                        </div>

                                        <div className="w-8 h-8 rounded-lg bg-orange-500 text-white font-bold flex items-center justify-center text-xs uppercase shrink-0">
                                          {u.full_name?.charAt(0) || "U"}
                                        </div>

                                        <div className="min-w-0 flex-1">
                                          <p className={`text-xs font-bold truncate ${isUserSelected ? "text-orange-900" : "text-sunset-dark"}`}>
                                            {u.full_name}
                                          </p>
                                          <p className="text-[10px] text-gray-400 truncate">{u.email}</p>
                                        </div>
                                      </div>
                                    );
                                  })}
                                </div>
                              ) : (
                                <p className="text-xs text-gray-400 italic text-center py-3">
                                  No users found in this role.
                                </p>
                              )}
                            </div>
                          )}
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}
            </div>

            {/* Modal Footer */}
            <div className="px-5 sm:px-8 py-4 sm:py-5 border-t border-orange-500/10 flex flex-row justify-between items-center gap-3 shrink-0 bg-gray-50/50">
              <span className="text-xs font-bold text-sunset-dark/60 hidden sm:inline">
                {formData.permissions.length} Perms · {formData.assigned_user_ids.length} Users Selected
              </span>

              <div className="flex items-center gap-3 w-full sm:w-auto justify-end">
                <Button
                  variant="ghost"
                  onClick={() => {
                    setIsAddEditOpen(false);
                    setEditingGroup(null);
                  }}
                  className="flex-1 sm:flex-none px-6 h-11 text-xs sm:text-sm bg-white border"
                >
                  Cancel
                </Button>

                <Button
                  onClick={handleSaveGroup}
                  disabled={isSaving}
                  className="flex-1 sm:flex-none px-8 h-11 text-xs sm:text-sm flex items-center justify-center shadow-md bg-orange-500 text-white hover:bg-orange-600"
                >
                  {isSaving && <Loader2 className="w-4 h-4 animate-spin mr-2 shrink-0" />}
                  {isSaving ? "Saving Group..." : "Save Permission Group"}
                </Button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* 3. Delete Confirmation Modal */}
      {deletingGroup && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center p-4 bg-sunset-dark/40 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white w-full max-w-lg rounded-3xl shadow-2xl flex flex-col overflow-hidden">
            <div className="px-6 py-5 border-b border-orange-500/10 flex justify-between items-center shrink-0">
              <h2 className="text-lg font-black text-red-600">Delete Permission Group</h2>
              <button onClick={() => setDeletingGroup(null)} className="p-2 hover:bg-gray-100 rounded-full text-gray-500 transition-colors">
                <X size={20} />
              </button>
            </div>
            <div className="p-6 flex-1">
              <p className="font-semibold text-sunset-dark text-sm sm:text-base mb-6">
                Are you sure you want to delete this group? Assigned users will lose permissions inherited from this group.
              </p>
              <div className="p-4 sm:p-5 bg-red-50 text-red-700 rounded-2xl border border-red-100 font-bold flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-red-100 text-red-600 flex items-center justify-center shrink-0">
                  <ShieldCheck size={20} />
                </div>
                <div>
                  <span className="block text-[10px] uppercase tracking-widest font-black opacity-50">
                    Deleting Group
                  </span>
                  <span className="text-lg font-black block mt-0.5">{deletingGroup.name}</span>
                </div>
              </div>
            </div>
            <div className="px-5 sm:px-8 py-4 sm:py-5 border-t border-orange-500/10 flex flex-row justify-end items-center gap-3 bg-gray-50/50 shrink-0">
              <Button variant="ghost" onClick={() => setDeletingGroup(null)} className="flex-1 sm:flex-none text-sm h-11 border bg-white shadow-sm">
                Cancel
              </Button>
              <Button variant="danger" onClick={handleDeleteGroup} className="flex-1 sm:flex-none text-sm h-11 shadow-md">
                Delete
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* 主体页面内容 */}
      <div className="space-y-6 animate-in fade-in zoom-in-95 duration-300">
        <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-sunset-dark">Permission Groups</h1>
            <p className="text-sm font-semibold text-sunset-dark/60 mt-1">
              Manage dynamic access control groups and user permissions.
            </p>
          </div>

          <div className="flex items-center gap-2">
            <Button
              onClick={openAddModal}
              className="px-5 py-2.5 text-sm h-auto flex items-center whitespace-nowrap shadow-md hover:shadow-lg transition-all bg-orange-500 text-white hover:bg-orange-600"
            >
              <Plus size={16} className="mr-1.5 shrink-0" /> Add Permission Group
            </Button>
          </div>
        </header>

        {/* Toolbar */}
        <div className="flex flex-col md:flex-row items-center gap-4 bg-white p-4 rounded-3xl border border-orange-500/10 shadow-sm">
          <div className="relative w-full md:flex-1 shrink-0">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-sunset-dark/40" size={18} />
            <Input
              placeholder="Search permission groups..."
              className="pl-11 bg-white border border-orange-500/30 hover:border-orange-500 rounded-2xl shadow-sm h-11 w-full focus:ring-2 focus:ring-orange-500/30 font-medium transition-all"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              autoComplete="off"
            />
          </div>

          <button
            onClick={fetchGroups}
            className="h-11 px-4 bg-orange-50 text-orange-600 hover:bg-orange-100 rounded-2xl transition-colors flex items-center gap-2 text-xs font-bold shrink-0 border border-orange-200"
            title="Refresh List"
          >
            <RefreshCw size={16} className={isLoading ? "animate-spin" : ""} /> Refresh
          </button>
        </div>

        {/* 栅格展示卡片列表 */}
        {isLoading ? (
          <div className="text-center py-20 bg-white rounded-[24px] border border-gray-100 shadow-sm">
            <Loader2 className="animate-spin text-orange-500 mx-auto w-10 h-10" />
          </div>
        ) : groups.length === 0 ? (
          <div className="text-center py-20 font-semibold text-gray-400 bg-white rounded-[24px] border border-gray-100 shadow-sm">
            No permission groups found matching search criteria.
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 xl:grid-cols-3 gap-6">
            {groups.map((g) => (
              <Card
                key={g.id}
                className="p-6 rounded-[24px] border border-gray-100 shadow-sm hover:border-orange-500/30 hover:shadow-md transition-all flex flex-col justify-between group"
              >
                <div>
                  <div className="flex items-start justify-between mb-4">
                    <div className="w-12 h-12 rounded-2xl bg-orange-500/10 text-orange-600 flex items-center justify-center shrink-0">
                      <ShieldCheck size={24} />
                    </div>

                    <div className="flex gap-1.5">
                      <button
                        onClick={() => setViewingGroup(g)}
                        className="p-2 rounded-xl text-gray-400 hover:text-blue-500 hover:bg-blue-50 transition-colors"
                        title="View Group"
                      >
                        <Shield size={18} />
                      </button>

                      <button
                        onClick={() => openEditModal(g)}
                        className="p-2 rounded-xl text-gray-400 hover:text-emerald-500 hover:bg-emerald-50 transition-colors"
                        title="Edit Group"
                      >
                        <Edit2 size={18} />
                      </button>

                      <button
                        onClick={() => setDeletingGroup(g)}
                        className="p-2 rounded-xl text-gray-400 hover:text-red-500 hover:bg-red-50 transition-colors"
                        title="Delete Group"
                      >
                        <Trash2 size={18} />
                      </button>
                    </div>
                  </div>

                  <h3 className="font-extrabold text-sunset-dark text-lg">{g.name}</h3>
                  <p className="text-xs text-sunset-dark/60 font-medium mt-1 line-clamp-2 min-h-[32px]">
                    {g.description || "No description provided."}
                  </p>
                </div>

                <div className="mt-6 pt-4 border-t border-gray-100 flex items-center justify-between text-xs font-extrabold text-sunset-dark/70">
                  <span className="flex items-center gap-1 bg-slate-50 px-2.5 py-1 rounded-lg border border-gray-100">
                    <Lock size={14} className="text-orange-500" /> {g.permissions?.length || 0} Rights
                  </span>

                  <span className="flex items-center gap-1 bg-slate-50 px-2.5 py-1 rounded-lg border border-gray-100">
                    <Users size={14} className="text-blue-500" /> {g.users?.length || 0} Members
                  </span>
                </div>
              </Card>
            ))}
          </div>
        )}
      </div>
    </>
  );
}