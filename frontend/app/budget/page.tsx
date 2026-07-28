"use client";

import React, { useState, useEffect, useCallback, useMemo } from "react";
import Link from "next/link";
import { Card, Button, Input, Toast } from "@/components/ui";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Plus, Edit2, Trash2, RefreshCw, CheckCircle, AlertCircle, AlertTriangle, Loader2, X, ArrowRight } from "lucide-react";
import * as Icons from "lucide-react";
import api from "@/lib/axios";

// 动态图标组件
const DynamicIcon = ({ name, className, style, size = 20 }: { name: string; className?: string; style?: React.CSSProperties, size?: number }) => {
  const IconComponent = (Icons as any)[name] || Icons.Tag;
  return <IconComponent className={className} style={style} size={size} />;
};

interface Category {
  id: number;
  name: string;
  icon: string;
  color: string;
  type_id?: number;
  type?: { id: number; name: string };
}

interface Budget {
  id: number;
  category: Category;
  amount: number;
  month: number;
  year: number;
  spent: number;
  remaining: number;
  percentage: number;
}

const MONTHS = [
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
];

function extractArray(data: unknown): any[] {
  if (Array.isArray(data)) return data;
  if (data && typeof data === "object") {
    const obj = data as Record<string, unknown>;
    for (const key of ["data", "items", "result", "budgets", "categories"]) {
      if (Array.isArray(obj[key])) return obj[key] as any[];
    }
  }
  return [];
}

// 帮助函数：计算剩余天数
function getDaysLeftText(year: number, month: number) {
  const now = new Date();
  const currentYear = now.getFullYear();
  const currentMonth = now.getMonth() + 1;
  const currentDay = now.getDate();

  if (year < currentYear || (year === currentYear && month < currentMonth)) {
    return "Month ended";
  }
  if (year > currentYear || (year === currentYear && month > currentMonth)) {
    return "Upcoming";
  }
  
  const daysInMonth = new Date(year, month, 0).getDate();
  const daysLeft = daysInMonth - currentDay;
  return daysLeft === 0 ? "Last day" : `${daysLeft} days left`;
}

// AI 分析状态算法
function getAiInsight(b: Budget) {
  const remainingRatio = 100 - b.percentage;
  const daysLeftText = getDaysLeftText(b.year, b.month);
  const catName = b.category?.name || "this category";

  if (b.percentage >= 100) {
    return {
      status: "Over Budget",
      icon: AlertCircle,
      colorClass: "text-red-600",
      bgClass: "bg-red-500",
      cardClass: "border-red-200 bg-white hover:border-red-300",
      message: `You've exceeded your ${catName} budget! Please stop spending.`,
    };
  }
  
  if (remainingRatio <= 20) {
    return {
      status: "Warning",
      icon: AlertTriangle,
      colorClass: "text-red-500",
      bgClass: "bg-red-500",
      cardClass: "border-red-200 bg-white hover:border-red-300",
      message: `Only ${remainingRatio.toFixed(1)}% remaining! You've spent RM ${b.spent.toFixed(2)} with ${daysLeftText}.`,
    };
  }

  if (remainingRatio <= 50) {
    return {
      status: "Watch It",
      icon: AlertTriangle,
      colorClass: "text-amber-500",
      bgClass: "bg-amber-400",
      cardClass: "border-amber-200 bg-white hover:border-amber-300",
      message: `You're halfway through your ${catName} limit. Keep an eye on expenses for the next ${daysLeftText}.`,
    };
  }

  return {
    status: "On Track",
    icon: CheckCircle,
    colorClass: "text-emerald-500",
    bgClass: "bg-emerald-400",
    cardClass: "border-gray-100 bg-white hover:border-emerald-200",
    message: `Looking good! You have RM ${b.remaining.toFixed(2)} left with ${daysLeftText}.`,
  };
}

export default function BudgetPage() {
  const [toast, setToast] = useState<{ message: string; type: "success" | "error" | "warning" } | null>(null);
  const [budgets, setBudgets] = useState<Budget[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  
  // States
  const [loading, setLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [analyzing, setAnalyzing] = useState(false);
  
  // Modals
  const [isAddOpen, setIsAddOpen] = useState(false);
  const [editingBudget, setEditingBudget] = useState<Budget | null>(null);
  const [deletingBudget, setDeletingBudget] = useState<Budget | null>(null);

  // Filters
  const now = new Date();
  const [selectedMonth, setSelectedMonth] = useState<number | "all">("all");
  const [selectedYear, setSelectedYear] = useState<number | "all">("all");

  // Form
  const [formData, setFormData] = useState({
    category_id: "",
    amount: "",
    month: String(now.getMonth() + 1),
    year: String(now.getFullYear())
  });
  const [errors, setErrors] = useState<any>({});

  const showToast = (message: string, type: "success" | "error" | "warning" = "success") => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  // 🌟 动态计算：前 10 年至后 10 年的年份数组 (例如 2016 - 2036)
  const filterYears = useMemo(() => {
    const currentYear = new Date().getFullYear();
    const list = [];
    for (let y = currentYear - 10; y <= currentYear + 10; y++) {
      list.push(y);
    }
    return list;
  }, []);

  const fetchCategories = useCallback(async () => {
    try {
      const res = await api.get("/categories", { params: { status: "1" } });
      setCategories(extractArray(res.data));
    } catch (err) {
      console.error("fetchCategories error:", err);
    }
  }, []);

  const fetchBudgets = useCallback(async () => {
    try {
      setLoading(true);
      const res = await api.get("/budget/list");
      const arr = extractArray(res.data);
      
      const filtered = arr.filter((b: any) => {
        const matchMonth = selectedMonth === "all" || Number(b.month) === selectedMonth;
        const matchYear = selectedYear === "all" || Number(b.year) === selectedYear;
        return matchMonth && matchYear;
      });

      const safeBudgets: Budget[] = filtered.map((b: any) => ({
        ...b,
        amount: Number(b.amount) || 0,
        spent: Number(b.spent) || 0,
        remaining: Number(b.remaining) || 0,
        percentage: Number(b.percentage) || 0,
      }));

      setBudgets(safeBudgets);
    } catch (err: any) {
      showToast(err?.response?.data?.message || "Failed to load budgets", "error");
    } finally {
      setLoading(false);
    }
  }, [selectedMonth, selectedYear]);

  useEffect(() => { fetchCategories(); }, [fetchCategories]);
  useEffect(() => { fetchBudgets(); }, [fetchBudgets]);

  // 按 Category 的 Type 动态分组
  const groupedBudgets = useMemo(() => {
    const groups: { [key: string]: { typeName: string; items: Budget[] } } = {};

    budgets.forEach((b) => {
      const typeName = b.category?.type?.name || (String(b.category?.type_id) === '2' ? 'Income' : 'Expense');
      const key = typeName.toLowerCase();

      if (!groups[key]) {
        groups[key] = {
          typeName: typeName,
          items: [],
        };
      }
      groups[key].items.push(b);
    });

    return Object.values(groups);
  }, [budgets]);

  const openAdd = () => {
    setErrors({});
    const defaultCatId = categories.length > 0 ? String(categories[0].id) : "";
    setFormData({
      category_id: defaultCatId,
      amount: "",
      month: String(now.getMonth() + 1),
      year: String(now.getFullYear())
    });
    setIsAddOpen(true);
  };

  const openEdit = (b: Budget) => {
    setErrors({});
    setFormData({
      category_id: String(b.category?.id || ""),
      amount: String(b.amount),
      month: String(b.month),
      year: String(b.year)
    });
    setEditingBudget(b);
  };

  const closeForm = () => {
    setIsAddOpen(false);
    setEditingBudget(null);
  };

  const handleSave = async () => {
    if (categories.length === 0) {
      showToast("Please add a Category first.", "warning");
      return;
    }

    setIsSaving(true);
    setErrors({});
    try {
      const payload = {
        category_id: Number(formData.category_id),
        amount: parseFloat(formData.amount),
        month: Number(formData.month),
        year: Number(formData.year),
      };
      
      if (editingBudget) {
        await api.post(`/budget/update/${editingBudget.id}`, payload);
        showToast("Budget updated successfully!", "success");
      } else {
        await api.post("/budget/create", payload);
        showToast("Budget created successfully!", "success");
      }
      closeForm();
      fetchBudgets();
    } catch (error: any) {
      if (error.response && error.response.status === 422) {
        setErrors(error.response.data.errors);
      } else {
        showToast(error.response?.data?.message || error.response?.data?.error || "Operation failed.", "error");
      }
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = async () => {
    try {
      await api.delete(`/budget/delete/${deletingBudget?.id}`);
      showToast("Budget deleted successfully", "success");
      setDeletingBudget(null);
      fetchBudgets();
    } catch (error: any) {
      showToast(error.response?.data?.message || error.response?.data?.error || "Failed to delete budget", "error");
      setDeletingBudget(null);
    }
  };

  const handleReanalyze = async () => {
    setAnalyzing(true);
    await new Promise(r => setTimeout(r, 1200));
    setAnalyzing(false);
    showToast("AI analysis refreshed!", "success");
  };

  return (
    <div className="space-y-6 animate-in fade-in zoom-in-95 duration-300 pb-10">
      {toast && <div className="fixed top-4 right-4 z-[10000]"><Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} /></div>}

      {/* 1. Add / Edit Budget Modal */}
      {(isAddOpen || editingBudget) && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center p-3 sm:p-6 pb-20 md:pb-6 bg-sunset-dark/40 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white w-full max-w-lg rounded-3xl shadow-2xl flex flex-col max-h-[90vh] animate-in zoom-in-95 duration-200 overflow-hidden">
            <div className="px-6 py-5 border-b border-sunset-primary/10 flex justify-between items-center shrink-0">
              <h2 className="text-xl sm:text-2xl font-bold text-sunset-dark">{editingBudget ? "Edit Budget" : "Create Budget"}</h2>
              <button onClick={closeForm} className="p-2 hover:bg-gray-100 rounded-full text-gray-500 transition-colors">
                <X size={20} />
              </button>
            </div>

            <div className="p-6 overflow-y-auto custom-scrollbar flex-1 space-y-5">
              
              {/* Category 下拉预警框 */}
              <div>
                <div className="flex items-center justify-between pl-1 mb-1.5">
                  <label className="text-xs font-extrabold text-sunset-dark/70 tracking-widest block">Category</label>
                  {categories.length === 0 && (
                    <Link href="/categories" className="text-xs text-orange-600 hover:underline font-bold flex items-center gap-1">
                      + Add Category <ArrowRight size={12} />
                    </Link>
                  )}
                </div>

                {categories.length === 0 ? (
                  <div className="p-3.5 bg-amber-50 border border-amber-200/80 rounded-2xl flex items-center justify-between text-amber-900 text-xs font-semibold animate-in fade-in duration-200">
                    <div className="flex items-center gap-2.5">
                      <AlertCircle size={18} className="text-amber-600 shrink-0" />
                      <span>No active Category found. Please add a Category first.</span>
                    </div>
                    <Link
                      href="/categories"
                      className="px-3 py-1.5 bg-amber-600 hover:bg-amber-700 text-white rounded-xl text-xs font-bold transition-all shrink-0 shadow-sm flex items-center gap-1"
                    >
                      Go to Categories
                    </Link>
                  </div>
                ) : (
                  <Select value={formData.category_id} onValueChange={(val) => setFormData({...formData, category_id: val})}>
                    <SelectTrigger className="bg-white rounded-xl h-11 text-sm font-medium border-orange-500/80 hover:border-orange-500 text-sunset-dark shadow-sm">
                      <SelectValue placeholder="Select Category" />
                    </SelectTrigger>
                    <SelectContent className="z-[10050]">
                      {categories.map(c => (
                        <SelectItem key={c.id} value={String(c.id)}>
                          <div className="flex items-center gap-2">
                             <DynamicIcon name={c.icon} size={14} style={{ color: c.color }} />
                             <span>{c.name}</span>
                             <span className="text-[10px] text-gray-400 font-normal">
                               ({c.type?.name || (String(c.type_id) === '2' ? 'Income' : 'Expense')})
                             </span>
                          </div>
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                )}
                {errors.category_id && <p className="text-xs text-red-500 mt-1 pl-1">{errors.category_id[0]}</p>}
              </div>

              <div>
                <label className="text-xs font-extrabold text-sunset-dark/70 tracking-widest pl-1 mb-1.5 block">Limit Amount (RM)</label>
                <Input 
                  type="number" 
                  placeholder="e.g. 500.00" 
                  value={formData.amount} 
                  onChange={(e) => setFormData({...formData, amount: e.target.value})} 
                  className="h-11 text-sm bg-white border-orange-500/80 hover:border-orange-500 focus:border-orange-500" 
                />
                {errors.amount && <p className="text-xs text-red-500 mt-1 pl-1">{errors.amount[0]}</p>}
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-xs font-extrabold text-sunset-dark/70 tracking-widest pl-1 mb-1.5 block">Month</label>
                  <Select value={formData.month} onValueChange={(val) => setFormData({...formData, month: val})}>
                    <SelectTrigger className="bg-white rounded-xl h-11 text-sm font-medium border-orange-500/80 hover:border-orange-500 text-sunset-dark shadow-sm">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent className="z-[10050]">
                      {MONTHS.map((m, i) => <SelectItem key={i} value={String(i+1)}>{m}</SelectItem>)}
                    </SelectContent>
                  </Select>
                  {errors.month && <p className="text-xs text-red-500 mt-1 pl-1">{errors.month[0]}</p>}
                </div>
                <div>
                  <label className="text-xs font-extrabold text-sunset-dark/70 tracking-widest pl-1 mb-1.5 block">Year</label>
                  <Select value={formData.year} onValueChange={(val) => setFormData({...formData, year: val})}>
                    <SelectTrigger className="bg-white rounded-xl h-11 text-sm font-medium border-orange-500/80 hover:border-orange-500 text-sunset-dark shadow-sm">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent className="z-[10050]">
                      {filterYears.map(y => <SelectItem key={y} value={String(y)}>{y}</SelectItem>)}
                    </SelectContent>
                  </Select>
                  {errors.year && <p className="text-xs text-red-500 mt-1 pl-1">{errors.year[0]}</p>}
                </div>
              </div>
            </div>

            <div className="px-6 py-5 border-t border-sunset-primary/10 flex flex-row justify-end items-center gap-3 shrink-0 bg-gray-50/50">
              <Button variant="ghost" className="flex-1 sm:flex-none px-6 h-11 text-sm bg-white border" onClick={closeForm}>Cancel</Button>
              <Button 
                onClick={handleSave} 
                disabled={isSaving || categories.length === 0} 
                className="flex-1 sm:flex-none rounded-xl px-8 h-11 text-sm flex items-center justify-center shadow-md bg-orange-500 text-white hover:bg-orange-600 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isSaving && <Loader2 className="w-4 h-4 animate-spin mr-2 shrink-0" />}
                {isSaving ? "Saving..." : "Save Budget"}
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* 2. Delete Confirmation Modal */}
      {deletingBudget && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center p-4 bg-sunset-dark/40 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white w-full max-w-lg rounded-3xl shadow-2xl flex flex-col overflow-hidden">
            <div className="px-6 py-5 border-b border-sunset-primary/10 flex justify-between items-center shrink-0">
              <h2 className="text-lg font-black text-red-600">Delete Budget</h2>
              <button onClick={() => setDeletingBudget(null)} className="p-2 hover:bg-gray-100 rounded-full text-gray-500 transition-colors">
                <X size={20} />
              </button>
            </div>
            <div className="p-6 flex-1">
              <p className="font-semibold text-sunset-dark text-sm sm:text-base mb-6">Are you sure you want to delete this budget? This action cannot be undone.</p>
              <div className="p-4 sm:p-5 bg-red-50 text-red-700 rounded-2xl border border-red-100 font-bold flex items-center gap-3">
                 <div className="w-10 h-10 rounded-xl bg-red-100 text-red-600 flex items-center justify-center shrink-0">
                   <DynamicIcon name={deletingBudget?.category?.icon || "Tag"} />
                 </div>
                 <div>
                   <span className="block text-[10px] uppercase tracking-widest font-black opacity-50">Deleting Budget Limit</span>
                   <span className="text-lg font-black block mt-0.5">{deletingBudget?.category?.name} - RM {deletingBudget.amount.toFixed(2)}</span>
                 </div>
              </div>
            </div>
            <div className="px-5 sm:px-8 py-4 sm:py-5 border-t border-sunset-primary/10 flex flex-row justify-end items-center gap-3 bg-gray-50/50 shrink-0">
              <Button variant="ghost" onClick={() => setDeletingBudget(null)} className="flex-1 sm:flex-none text-sm h-11 border bg-white shadow-sm">Cancel</Button>
              <Button variant="danger" onClick={handleDelete} className="flex-1 sm:flex-none rounded-xl text-sm h-11 shadow-md">Delete</Button>
            </div>
          </div>
        </div>
      )}

      {/* 页面头部及过滤器 */}
      <header className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-black text-sunset-dark tracking-tight">Budgets</h1>
          <p className="text-sm font-medium text-sunset-dark/60 mt-1">Set limits & track your spending with AI insights</p>
        </div>
        
        <div className="flex items-center gap-3 flex-wrap">
          <div className="flex items-center gap-2 bg-white border border-orange-500/80 rounded-2xl px-4 py-2 shadow-sm">
            <select
              value={selectedMonth}
              onChange={e => setSelectedMonth(e.target.value === "all" ? "all" : Number(e.target.value))}
              className="text-xs font-extrabold text-sunset-dark bg-transparent focus:outline-none cursor-pointer"
            >
              <option value="all">All Months</option>
              {MONTHS.map((m, i) => <option key={i} value={i+1}>{m}</option>)}
            </select>
            <div className="w-px h-4 bg-orange-500/20 mx-1"></div>
            <select
              value={selectedYear}
              onChange={e => setSelectedYear(e.target.value === "all" ? "all" : Number(e.target.value))}
              className="text-xs font-extrabold text-sunset-dark bg-transparent focus:outline-none cursor-pointer"
            >
              <option value="all">All Years</option>
              {filterYears.map(y => <option key={y} value={y}>{y}</option>)}
            </select>
          </div>

          <button 
            onClick={handleReanalyze} 
            disabled={analyzing}
            className="w-10 h-10 rounded-2xl bg-white shadow-sm border border-orange-500/80 flex items-center justify-center text-sunset-dark hover:bg-gray-50 transition-colors shrink-0"
            title="Re-analyze AI Insights"
          >
            <RefreshCw size={18} className={`${analyzing ? "animate-spin text-orange-500" : ""}`} />
          </button>

          <Button onClick={openAdd} className="rounded-xl px-5 shadow-md hover:shadow-lg bg-orange-500 hover:bg-orange-600">
            <Plus size={18} className="mr-2 inline" /> Add Budget
          </Button>
        </div>
      </header>

      {/* 预算列表展示 (根据 Category Type 动态分组展示) */}
      {loading ? (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {[1,2,3,4].map(i => <div key={i} className="h-64 bg-white/40 rounded-3xl animate-pulse shadow-sm" />)}
        </div>
      ) : budgets.length === 0 ? (
        <Card className="text-center py-20 border-dashed border-2 border-orange-500/20 bg-transparent shadow-none">
          <div className="w-16 h-16 bg-white rounded-full flex items-center justify-center mx-auto mb-4 shadow-sm">
            <AlertCircle className="text-orange-500/40" size={24} />
          </div>
          <p className="text-sunset-dark/60 font-semibold text-lg">No budgets found</p>
          <p className="text-sm text-sunset-dark/40 mt-1 mb-6">Try changing your filters or create a new one.</p>
          <Button onClick={openAdd} className="rounded-xl shadow-md bg-orange-500 hover:bg-orange-600">
            <Plus size={16} className="mr-2 inline" /> Create First Budget
          </Button>
        </Card>
      ) : (
        <div className="space-y-8">
          {groupedBudgets.map((group) => {
            const isIncome = group.typeName.toLowerCase().includes("income");
            const headerColor = isIncome ? "text-emerald-600" : "text-red-500";
            const badgeBg = isIncome ? "bg-emerald-50 text-emerald-600" : "bg-red-50 text-red-500";

            return (
              <div key={group.typeName} className="space-y-4">
                <h2 className={`text-lg font-black flex items-center gap-2 border-b border-gray-100 pb-2 tracking-wide ${headerColor}`}>
                  {group.typeName} <span className={`text-xs px-2.5 py-0.5 rounded-full font-bold ${badgeBg}`}>({group.items.length})</span>
                </h2>

                <div className="grid grid-cols-1 lg:grid-cols-2 2xl:grid-cols-2 gap-6">
                  {group.items.map((b) => {
                    const insight = getAiInsight(b);
                    const StatusIcon = insight.icon;
                    const daysLeftText = getDaysLeftText(b.year, b.month);
                    const typeName = b.category?.type?.name || (String(b.category?.type_id) === '2' ? 'Income' : 'Expense');

                    return (
                      <Card 
                        key={b.id} 
                        className={`p-6 rounded-[24px] border shadow-sm transition-all duration-300 ${insight.cardClass}`}
                      >
                        <div className="flex justify-between items-start mb-6">
                          <div className="flex items-center gap-4 min-w-0 flex-1">
                            <div 
                              className="w-12 h-12 rounded-2xl flex items-center justify-center shrink-0"
                              style={{ backgroundColor: `${b.category?.color || '#f97316'}15`, color: b.category?.color || '#f97316' }}
                            >
                              <DynamicIcon name={b.category?.icon || "Tag"} size={24} />
                            </div>
                            <div className="min-w-0 flex-1">
                              <div className="flex items-center gap-2 flex-wrap">
                                <h3 className="font-extrabold text-sunset-dark text-lg truncate">{b.category?.name || "Unknown"}</h3>
                                
                                {/* 带有颜色的 Category Type 标签 */}
                                <span className={`inline-flex items-center px-2 py-0.5 rounded-md text-[10px] font-extrabold uppercase tracking-wider shrink-0 ${
                                  typeName.toLowerCase().includes('income')
                                    ? 'bg-emerald-50 text-emerald-600 border border-emerald-200/60'
                                    : 'bg-orange-50 text-orange-600 border border-orange-200/60'
                                }`}>
                                  {typeName}
                                </span>
                              </div>

                              {(selectedMonth === "all" || selectedYear === "all") && (
                                <p className="text-[10px] font-bold text-gray-400 uppercase tracking-wider mt-0.5">{MONTHS[b.month - 1]} {b.year}</p>
                              )}
                            </div>
                          </div>
                          
                          <div className="flex gap-2 shrink-0">
                            <button onClick={() => openEdit(b)} className="w-8 h-8 rounded-full flex items-center justify-center text-gray-400 hover:text-blue-500 hover:bg-blue-50 transition-colors bg-white border border-gray-100 shadow-sm">
                              <Edit2 size={16} />
                            </button>
                            <button onClick={() => setDeletingBudget(b)} className="w-8 h-8 rounded-full flex items-center justify-center text-gray-400 hover:text-red-500 hover:bg-red-50 transition-colors bg-white border border-gray-100 shadow-sm">
                              <Trash2 size={16} />
                            </button>
                          </div>
                        </div>

                        <div className="flex items-baseline gap-2 mb-3">
                          <span className="text-3xl sm:text-4xl font-black text-sunset-dark tracking-tight">
                            RM {b.spent.toFixed(2)}
                          </span>
                          <span className="text-xs sm:text-sm font-semibold text-gray-400">
                            of RM {b.amount.toFixed(2)}
                          </span>
                        </div>

                        <div className="h-2.5 w-full bg-black/5 rounded-full mb-3 overflow-hidden">
                          <div 
                            className={`h-full rounded-full transition-all duration-1000 ease-out ${insight.bgClass}`}
                            style={{ width: `${Math.min(b.percentage, 100)}%` }}
                          />
                        </div>

                        <div className="flex justify-between items-center text-xs font-semibold text-gray-500 mb-6">
                          <span>{b.percentage.toFixed(0)}% Used · {daysLeftText}</span>
                          <span>RM {Math.max(b.remaining, 0).toFixed(2)} left</span>
                        </div>

                        <div className="flex items-start gap-3">
                          <StatusIcon size={20} className={`shrink-0 mt-0.5 ${insight.colorClass}`} />
                          <div>
                            <h4 className={`text-sm font-bold mb-0.5 ${insight.colorClass}`}>
                              {insight.status}
                            </h4>
                            <p className="text-xs font-medium text-gray-500 leading-relaxed">
                              {insight.message}
                            </p>
                          </div>
                        </div>

                      </Card>
                    );
                  })}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}