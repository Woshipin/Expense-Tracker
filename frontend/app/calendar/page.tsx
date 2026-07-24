"use client";

import React, { useState, useEffect, useMemo } from "react";
import Link from "next/link";
import { Card, Button, Input, Toast } from "@/components/ui";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { ChevronLeft, ChevronRight, Plus, Edit2, Trash2, Loader2, X, Wallet, Clock, AlertCircle, ArrowRight } from "lucide-react";
import api from "@/lib/axios";

// 价格格式化辅助函数
const formatPrice = (price: any) => {
  const num = parseFloat(price);
  if (isNaN(num)) return "0.00";
  return num.toFixed(2);
};

export default function CalendarPage() {
  const [toast, setToast] = useState<{message:string, type:'success'|'error'|'warning'}|null>(null);
  
  // 日历年月状态
  const [currentDate, setCurrentDate] = useState(new Date());
  
  // 数据状态
  const [calendarData, setCalendarData] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  
  // 原始动态选项 (存储从 DB 获取的所有 active 状态数据)
  const [typesList, setTypesList] = useState<any[]>([]); // 数据库状态为 1 的 Types 列表
  const [allCategories, setAllCategories] = useState<any[]>([]);
  const [allMethods, setAllMethods] = useState<any[]>([]);

  // 弹窗状态
  const [selectedDateStr, setSelectedDateStr] = useState<string | null>(null);
  const [isRecordListOpen, setIsRecordListOpen] = useState(false);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [deletingRecord, setDeletingRecord] = useState<any>(null);
  
  // 表单状态
  const [editingRecord, setEditingRecord] = useState<any>(null);
  const [activeTypeId, setActiveTypeId] = useState<string>(""); // 当前选中的 Type ID
  const [isSaving, setIsSaving] = useState(false);
  const [formData, setFormData] = useState({
    title: "", description: "", price: "", date: "", time: "", payment_method_id: "", category_id: "" 
  });
  const [errors, setErrors] = useState<any>({});

  const showToast = (message: string, type: 'success'|'error'|'warning' = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  // 1. 从 DB 获取当前用户 status=1 的 Types, Categories 和 Payment Methods
  const fetchOptions = async () => {
    try {
      const [catsRes, methodsRes, typesRes] = await Promise.all([
        api.get('/categories', { params: { status: '1' } }), 
        api.get('/payment-methods', { params: { status: '1' } }),
        api.get('/types', { params: { status: '1' } })
      ]);

      const tList = typesRes.data.data || typesRes.data || [];
      const activeTypes = tList.filter((t: any) => String(t.status) === '1');
      setTypesList(activeTypes);

      setAllCategories(catsRes.data.data || catsRes.data || []);
      setAllMethods(methodsRes.data.data || methodsRes.data || []);
    } catch (e) {
      console.error("Failed to load options", e);
    }
  };

  const fetchCalendarData = async () => {
    setIsLoading(true);
    try {
      const year = currentDate.getFullYear();
      const month = currentDate.getMonth() + 1;
      const res = await api.get(`/calendar?year=${year}&month=${month}`);
      setCalendarData(res.data.data || []);
    } catch (error) {
      showToast("Failed to fetch calendar data", "error");
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchOptions();
  }, []);

  useEffect(() => {
    fetchCalendarData();
  }, [currentDate]);

  // 根据当前 selected activeTypeId 过滤可用的 Category 列表
  const activeCategoryOptions = useMemo(() => {
    if (!activeTypeId) return [];
    return allCategories.filter((c: any) => 
      String(c.status) === '1' && String(c.type_id) === String(activeTypeId)
    );
  }, [allCategories, activeTypeId]);

  // 根据当前 selected activeTypeId 过滤可用的 Payment Method 列表
  const activeMethodOptions = useMemo(() => {
    if (!activeTypeId) return [];
    return allMethods.filter((m: any) => 
      String(m.status) === '1' && String(m.type_id) === String(activeTypeId)
    );
  }, [allMethods, activeTypeId]);

  // 日历计算算法
  const year = currentDate.getFullYear();
  const month = currentDate.getMonth(); 
  
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const firstDayOfMonth = new Date(year, month, 1).getDay();
  const startOffset = firstDayOfMonth === 0 ? 6 : firstDayOfMonth - 1; 

  const handlePrevMonth = () => setCurrentDate(new Date(year, month - 1, 1));
  const handleNextMonth = () => setCurrentDate(new Date(year, month + 1, 1));

  const getRecordsForDate = (dateStr: string) => {
    return calendarData.filter(item => {
      const itemDateStr = item.date ? String(item.date).substring(0, 10) : "";
      return itemDateStr === dateStr;
    });
  };

  const selectedDateRecords = useMemo(() => {
    if (!selectedDateStr) return [];
    return getRecordsForDate(selectedDateStr);
  }, [selectedDateStr, calendarData]);

  const handleDayClick = (dayNum: number) => {
    const formattedMonth = String(month + 1).padStart(2, '0');
    const formattedDay = String(dayNum).padStart(2, '0');
    const dateStr = `${year}-${formattedMonth}-${formattedDay}`;
    
    setSelectedDateStr(dateStr);
    setIsRecordListOpen(true);
  };

  // 切换 Type Tab 时更新 Category 和 Payment Method
  const handleTypeTabChange = (typeObj: any) => {
    const typeIdStr = String(typeObj.id);
    setActiveTypeId(typeIdStr);

    const cats = allCategories.filter((c: any) => 
      String(c.status) === '1' && String(c.type_id) === typeIdStr
    );
    const methods = allMethods.filter((m: any) => 
      String(m.status) === '1' && String(m.type_id) === typeIdStr
    );

    setFormData(prev => ({
      ...prev,
      category_id: cats.length > 0 ? String(cats[0].id) : "",
      payment_method_id: methods.length > 0 ? String(methods[0].id) : ""
    }));
  };

  const openForm = (record: any = null) => {
    setErrors({});
    if (record) {
      // 编辑模式
      setEditingRecord(record);
      const recordTypeId = String(record.type_id || record.category?.type_id || (typesList.length > 0 ? typesList[0].id : ""));
      setActiveTypeId(recordTypeId);
      
      setFormData({
        title: record.title, 
        description: record.description || "", 
        price: String(record.price), 
        date: String(record.date).substring(0, 10), 
        time: String(record.time).substring(0, 5),  
        payment_method_id: String(record.payment_method_id), 
        category_id: String(record.category_id) 
      });
    } else {
      // 新增模式：默认选中第一个 Active 的 Type
      setEditingRecord(null);
      const defaultType = typesList.length > 0 ? typesList[0] : null;
      const defaultTypeId = defaultType ? String(defaultType.id) : "";
      setActiveTypeId(defaultTypeId);

      const cats = allCategories.filter((c: any) => 
        String(c.status) === '1' && String(c.type_id) === defaultTypeId
      );
      const methods = allMethods.filter((m: any) => 
        String(m.status) === '1' && String(m.type_id) === defaultTypeId
      );

      const now = new Date();
      const defaultDate = selectedDateStr || now.toISOString().split('T')[0];
      const defaultTime = now.toTimeString().split(' ')[0].substring(0, 5);
      
      setFormData({
        title: "", description: "", price: "", 
        date: defaultDate, time: defaultTime, 
        payment_method_id: methods.length > 0 ? String(methods[0].id) : "", 
        category_id: cats.length > 0 ? String(cats[0].id) : "" 
      });
    }
    setIsRecordListOpen(false);
    setIsFormOpen(true);
  };

  const handleSave = async () => {
    if (activeCategoryOptions.length === 0 || activeMethodOptions.length === 0) {
      showToast("Please ensure you have active Category and Payment Method for this type.", "warning");
      return;
    }

    setIsSaving(true);
    setErrors({});
    
    // 判断当前选中的 Type 名称是否包含 income 词汇
    const currentTypeObj = typesList.find(t => String(t.id) === String(activeTypeId));
    const isIncome = currentTypeObj?.name?.toLowerCase().includes('income');
    const endpoint = isIncome ? '/incomes' : '/expenses';
    
    try {
      if (editingRecord) {
        await api.put(`${endpoint}/${editingRecord.id}`, formData);
        showToast('Record updated successfully!', 'success');
      } else {
        await api.post(endpoint, formData);
        showToast('Record added successfully!', 'success');
      }
      setIsFormOpen(false);
      fetchCalendarData();
      if (selectedDateStr) setIsRecordListOpen(true);
    } catch (error: any) {
      if (error.response && error.response.status === 422) setErrors(error.response.data.errors);
      else showToast(error.response?.data?.message || error.response?.data?.error || "Operation failed.", "error");
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!deletingRecord) return;
    const isIncome = deletingRecord.type === 'income' || deletingRecord.category?.type?.name?.toLowerCase().includes('income');
    const endpoint = isIncome ? '/incomes' : '/expenses';

    try {
      await api.delete(`${endpoint}/${deletingRecord.id}`);
      showToast('Record deleted successfully', 'success');
      setDeletingRecord(null);
      fetchCalendarData();
    } catch (error: any) {
      showToast(error.response?.data?.message || error.response?.data?.error || "Failed to delete record", "error");
      setDeletingRecord(null);
    }
  };

  const getMonthName = (m: number) => {
    const names = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
    return names[m];
  };

  return (
    <div className="space-y-6 animate-in fade-in zoom-in-95 duration-300">
      {toast && <div className="fixed top-4 right-4 z-[10000]"><Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} /></div>}
      
      <header className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-sunset-dark">Calendar</h1>
          <p className="text-sm font-medium text-sunset-dark/60 mt-1">Review your transactions day-by-day.</p>
        </div>
        <Button onClick={() => openForm(null)} className="px-5 py-2.5 text-sm h-auto flex items-center shadow-md bg-orange-500 text-white hover:bg-orange-600">
          <Plus size={16} className="mr-1.5 shrink-0" /> Add Record
        </Button>
      </header>

      <Card className="p-4 md:p-6 shadow-xl shadow-orange-500/5 border-2 border-orange-500/20 overflow-hidden bg-white/80 rounded-[24px]">
        {/* 日历头部：月份控制 */}
        <div className="flex items-center justify-between mb-8">
          <div className="flex items-center gap-3">
             <h2 className="text-xl sm:text-2xl font-black text-sunset-dark tracking-tight">{getMonthName(month)} {year}</h2>
             {isLoading && <Loader2 size={18} className="animate-spin text-orange-500" />}
          </div>
          <div className="flex gap-2">
            <button onClick={handlePrevMonth} className="p-2 rounded-xl border border-sunset-primary/20 text-sunset-dark hover:bg-orange-50 hover:text-orange-600 transition-colors"><ChevronLeft size={20} /></button>
            <button onClick={handleNextMonth} className="p-2 rounded-xl border border-sunset-primary/20 text-sunset-dark hover:bg-orange-50 hover:text-orange-600 transition-colors"><ChevronRight size={20} /></button>
          </div>
        </div>

        {/* 星期头部 */}
        <div className="grid grid-cols-7 gap-1 md:gap-2 mb-3">
          {['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map(day => (
            <div key={day} className="text-center text-[10px] sm:text-xs font-black text-sunset-dark/40 uppercase tracking-widest truncate">{day}</div>
          ))}
        </div>
        
        {/* 日历网格 */}
        <div className="grid grid-cols-7 gap-1 md:gap-2">
          {Array.from({ length: startOffset }).map((_, i) => (
             <div key={`empty-${i}`} className="min-h-[70px] md:min-h-[100px] rounded-xl sm:rounded-2xl border border-transparent bg-gray-50/50 opacity-50"></div>
          ))}

          {Array.from({ length: daysInMonth }).map((_, i) => {
            const dateNum = i + 1;
            const formattedMonth = String(month + 1).padStart(2, '0');
            const formattedDay = String(dateNum).padStart(2, '0');
            const dateStr = `${year}-${formattedMonth}-${formattedDay}`;
            
            const todayStr = new Date().toLocaleDateString('en-CA');
            const isToday = todayStr === dateStr;
            
            const dayRecords = getRecordsForDate(dateStr);
            const hasExpense = dayRecords.some(r => r.type === 'expense');
            const hasIncome = dayRecords.some(r => r.type === 'income');
            
            return (
              <div 
                key={dateNum} 
                onClick={() => handleDayClick(dateNum)}
                className={`min-h-[70px] md:min-h-[100px] rounded-xl sm:rounded-2xl border transition-all relative flex flex-col pt-6 sm:pt-8 pb-1 px-1 sm:px-2 cursor-pointer active:scale-[0.98]
                  ${isToday 
                    ? 'bg-orange-50 border-orange-500 shadow-sm' 
                    : 'bg-white border-sunset-primary/10 hover:border-orange-500/50 hover:shadow-md'
                  }
                `}
              >
                <span className={`text-sm sm:text-base font-bold absolute top-1 sm:top-2 left-1.5 sm:left-2 
                  ${isToday ? 'text-orange-600 bg-white px-1.5 rounded-md shadow-sm' : 'text-sunset-dark/70'}
                `}>
                  {dateNum}
                </span>
                
                {/* Desktop 端标签显示 */}
                <div className="mt-auto hidden sm:flex flex-col gap-1 justify-end">
                   {hasExpense && <div className="truncate text-[10px] sm:text-xs font-bold bg-red-50 text-red-600 px-1.5 sm:px-2 py-0.5 sm:py-1 rounded-md sm:rounded-lg text-right">Exp</div>}
                   {hasIncome && <div className="truncate text-[10px] sm:text-xs font-bold bg-emerald-50 text-emerald-600 px-1.5 sm:px-2 py-0.5 sm:py-1 rounded-md sm:rounded-lg text-right">Inc</div>}
                </div>
                
                {/* Mobile 端小圆点显示 */}
                <div className="absolute bottom-2 flex gap-1 justify-center w-full left-0 sm:hidden">
                  {hasExpense && <div className="w-1.5 h-1.5 rounded-full bg-red-500 shadow-sm" />}
                  {hasIncome && <div className="w-1.5 h-1.5 rounded-full bg-emerald-500 shadow-sm" />}
                </div>
              </div>
            );
          })}
        </div>
      </Card>

      {/* 1. 点击日期弹出的记录列表 */}
      {isRecordListOpen && selectedDateStr && (
        <div className="fixed inset-0 z-[9000] flex items-center justify-center p-4 bg-sunset-dark/40 backdrop-blur-sm animate-in fade-in duration-200">
           <div className="bg-white w-full max-w-lg rounded-[2rem] shadow-2xl flex flex-col max-h-[90vh] overflow-hidden">
              <div className="px-6 py-5 border-b border-sunset-primary/10 flex justify-between items-center bg-gray-50/50">
                <h2 className="text-xl font-black text-sunset-dark">Transactions</h2>
                <button onClick={() => setIsRecordListOpen(false)} className="p-2 bg-white border border-gray-200 hover:bg-gray-100 rounded-full text-gray-500 transition-colors">
                  <X size={18} />
                </button>
              </div>
              <div className="px-6 py-3 bg-orange-50 border-b border-orange-100 text-center font-bold text-orange-600 text-sm tracking-widest">
                 {selectedDateStr}
              </div>
              
              <div className="p-6 overflow-y-auto custom-scrollbar flex-1 space-y-3 min-h-[150px]">
                 {selectedDateRecords.length === 0 ? (
                    <div className="text-center py-10 text-gray-400 font-medium">No transactions on this date.</div>
                 ) : (
                    selectedDateRecords.map(r => (
                      <div key={`${r.type}-${r.id}`} className="flex justify-between items-center p-4 rounded-2xl border border-gray-100 bg-white shadow-sm hover:border-orange-500/30 transition-all group">
                        <div className="flex-1 min-w-0 pr-4">
                          <p className="font-extrabold text-sunset-dark text-base truncate">{r.title}</p>
                          <div className="flex items-center gap-2 mt-1">
                             <span className="text-xs font-bold text-sunset-dark/40 uppercase">{String(r.time).substring(0, 5)}</span>
                             <span className={`text-[9px] font-bold px-1.5 py-0.5 rounded uppercase tracking-wider ${r.type === 'income' ? 'bg-emerald-50 text-emerald-600' : 'bg-red-50 text-red-600'}`}>
                               {r.type}
                             </span>
                          </div>
                        </div>
                        <div className="flex flex-col items-end gap-2 shrink-0">
                          <span className={`font-black text-lg ${r.type === 'income' ? 'text-emerald-600' : 'text-red-500'}`}>
                            {r.type === 'income' ? '+' : '-'}RM {formatPrice(r.price)}
                          </span>
                          <div className="flex gap-1 opacity-100 sm:opacity-0 group-hover:opacity-100 transition-opacity">
                            <button onClick={() => openForm(r)} className="p-1.5 rounded-lg text-gray-400 hover:text-blue-500 hover:bg-blue-50 transition-colors"><Edit2 size={14}/></button>
                            <button onClick={() => setDeletingRecord(r)} className="p-1.5 rounded-lg text-gray-400 hover:text-red-500 hover:bg-red-50 transition-colors"><Trash2 size={14}/></button>
                          </div>
                        </div>
                      </div>
                    ))
                 )}
              </div>
              
              <div className="p-6 border-t border-sunset-primary/10 flex gap-3 flex-col sm:flex-row bg-gray-50/50">
                <Button variant="ghost" onClick={() => setIsRecordListOpen(false)} className="w-full sm:w-auto px-6 border bg-white shadow-sm">Close</Button>
                <Button onClick={() => openForm(null)} className="w-full flex-1 shadow-md bg-sunset-dark text-white hover:bg-black"><Plus size={16} className="mr-2 inline"/> Add Record</Button>
              </div>
           </div>
        </div>
      )}

      {/* 2. Add / Edit Shared Form Modal */}
      {isFormOpen && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center p-3 sm:p-6 pb-20 md:pb-6 bg-sunset-dark/40 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white w-full max-w-2xl xl:max-w-[950px] rounded-3xl sm:rounded-[2rem] shadow-2xl flex flex-col max-h-[calc(100vh-110px)] sm:max-h-[95vh] animate-in zoom-in-95 duration-200 overflow-hidden">
            <div className="px-5 sm:px-8 py-4 sm:py-6 border-b border-sunset-primary/10 flex justify-between items-center shrink-0 bg-gray-50/50">
              <h2 className="text-xl sm:text-2xl font-black text-sunset-dark tracking-tight">{editingRecord ? "Edit Record" : "Add Record"}</h2>
              <button onClick={() => { setIsFormOpen(false); if(selectedDateStr) setIsRecordListOpen(true); }} className="p-2 bg-white border border-gray-200 hover:bg-gray-100 rounded-full text-gray-500 transition-colors">
                <X size={20} />
              </button>
            </div>

            <div className="p-4 sm:p-6 md:p-8 overflow-y-auto custom-scrollbar flex-1">
              
              {/* 【核心修改处】：动态渲染当前 user_id 且 status=1 的 Types 选项卡 */}
              {typesList.length > 0 ? (
                <div className="flex bg-gray-100 p-1.5 rounded-2xl mb-6 max-w-sm mx-auto shadow-inner border border-gray-200/50">
                  {typesList.map((t: any) => {
                    const isSelected = String(activeTypeId) === String(t.id);
                    const isIncome = t.name?.toLowerCase().includes('income');
                    const activeTextColor = isIncome ? 'text-emerald-600' : 'text-red-600';

                    return (
                      <button 
                        key={t.id} 
                        type="button" 
                        disabled={!!editingRecord} 
                        onClick={() => handleTypeTabChange(t)} 
                        className={`flex-1 py-2.5 rounded-xl text-sm font-bold transition-all ${
                          isSelected 
                            ? `bg-white ${activeTextColor} shadow-sm border border-gray-200/50` 
                            : 'text-gray-500 hover:text-gray-700 disabled:opacity-50 disabled:cursor-not-allowed'
                        }`}
                      >
                        {t.name}
                      </button>
                    );
                  })}
                </div>
              ) : (
                <div className="p-3 mb-6 bg-amber-50 border border-amber-200/80 rounded-2xl flex items-center justify-between text-amber-900 text-xs font-semibold">
                  <div className="flex items-center gap-2">
                    <AlertCircle size={16} className="text-amber-600 shrink-0" />
                    <span>No active Transaction Types found.</span>
                  </div>
                  <Link href="/types" className="px-2.5 py-1 bg-amber-600 hover:bg-amber-700 text-white rounded-lg text-xs font-bold transition-all shrink-0">
                    Go to Types
                  </Link>
                </div>
              )}

              <div className="grid grid-cols-1 xl:grid-cols-2 gap-4 sm:gap-6 items-start">
                {/* Left Column */}
                <div className="bg-orange-50/40 rounded-2xl sm:rounded-[1.5rem] p-5 sm:p-6 border border-orange-100 flex flex-col gap-4 sm:gap-5 transition-colors">
                  <h3 className="text-xs sm:text-sm font-black uppercase tracking-widest flex items-center text-orange-600">
                    <Wallet size={16} className="mr-2" /> Basic Details
                  </h3>
                  <div>
                    <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-1 mb-1 block">Title</label>
                    <Input placeholder="E.g. Item Title" value={formData.title} onChange={(e) => setFormData({...formData, title: e.target.value})} className="h-10 sm:h-11 text-sm bg-white" />
                    {errors.title && <p className="text-xs text-red-500 mt-1 pl-1">{errors.title[0]}</p>}
                  </div>
                  <div>
                    <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-1 mb-1 block">Amount (RM)</label>
                    <Input type="number" step="0.01" placeholder="0.00" value={formData.price} onChange={(e) => setFormData({...formData, price: e.target.value})} className="h-10 sm:h-11 text-sm bg-white font-black text-sunset-dark" />
                    {errors.price && <p className="text-xs text-red-500 mt-1 pl-1">{errors.price[0]}</p>}
                  </div>
                  <div>
                    <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-1 mb-1 block">Description (Optional)</label>
                    <textarea placeholder="Enter description..." value={formData.description} onChange={(e) => setFormData({...formData, description: e.target.value})} className="w-full rounded-xl border border-orange-500/40 focus:border-orange-500 p-3 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-orange-500/30 transition-all min-h-[80px] custom-scrollbar" />
                    {errors.description && <p className="text-xs text-red-500 mt-1 pl-1">{errors.description[0]}</p>}
                  </div>
                </div>

                {/* Right Column */}
                <div className="bg-slate-50/80 rounded-2xl sm:rounded-[1.5rem] p-5 sm:p-6 border border-slate-200 flex flex-col gap-4 sm:gap-5">
                  <h3 className="text-xs sm:text-sm font-black text-sunset-dark/60 uppercase tracking-widest flex items-center">
                    <Clock size={16} className="mr-2 text-slate-500" /> Categorization
                  </h3>
                  
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-1 mb-1 block">Date</label>
                      <Input type="date" value={formData.date} onChange={(e) => setFormData({...formData, date: e.target.value})} className="h-10 sm:h-11 text-sm bg-white border-orange-500/30 focus:border-orange-500 focus:ring-orange-500/20" />
                      {errors.date && <p className="text-xs text-red-500 mt-1 pl-1">{errors.date[0]}</p>}
                    </div>
                    <div>
                      <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-1 mb-1 block">Time</label>
                      <Input type="time" value={formData.time} onChange={(e) => setFormData({...formData, time: e.target.value})} className="h-10 sm:h-11 text-sm bg-white border-orange-500/30 focus:border-orange-500 focus:ring-orange-500/20" />
                      {errors.time && <p className="text-xs text-red-500 mt-1 pl-1">{errors.time[0]}</p>}
                    </div>
                  </div>

                  {/* Category 下拉框与空状态 */}
                  <div>
                    <div className="flex items-center justify-between pl-1 mb-1.5">
                      <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/70 uppercase tracking-widest block">Category</label>
                      {activeCategoryOptions.length === 0 && (
                        <Link href="/categories" className="text-xs text-orange-600 hover:underline font-bold flex items-center gap-1">
                          + Add Category <ArrowRight size={12} />
                        </Link>
                      )}
                    </div>

                    {activeCategoryOptions.length === 0 ? (
                      <div className="p-3 bg-amber-50 border border-amber-200/80 rounded-xl flex items-center justify-between text-amber-900 text-xs font-semibold">
                        <div className="flex items-center gap-2">
                          <AlertCircle size={16} className="text-amber-600 shrink-0" />
                          <span>No Category found for this type.</span>
                        </div>
                        <Link href="/categories" className="px-2.5 py-1 bg-amber-600 hover:bg-amber-700 text-white rounded-lg text-xs font-bold transition-all shrink-0">
                          Go to Categories
                        </Link>
                      </div>
                    ) : (
                      <Select value={formData.category_id} onValueChange={(val) => setFormData({...formData, category_id: val})}>
                        <SelectTrigger className="bg-white rounded-xl h-10 sm:h-11 text-xs sm:text-sm font-medium text-sunset-dark shadow-sm border-orange-500/50 hover:border-orange-500 focus:ring-orange-500/30">
                          <SelectValue placeholder="Select Category" />
                        </SelectTrigger>
                        <SelectContent className="z-[10050]">
                          {activeCategoryOptions.map(c => <SelectItem key={c.id} value={String(c.id)}>{c.name}</SelectItem>)}
                        </SelectContent>
                      </Select>
                    )}
                    {errors.category_id && <p className="text-xs text-red-500 mt-1 pl-1">{errors.category_id[0]}</p>}
                  </div>

                  {/* Payment Method 下拉框与空状态 */}
                  <div>
                    <div className="flex items-center justify-between pl-1 mb-1.5">
                      <label className="text-[10px] sm:text-xs font-bold text-sunset-dark/70 uppercase tracking-widest block">Payment Method</label>
                      {activeMethodOptions.length === 0 && (
                        <Link href="/payment-methods" className="text-xs text-orange-600 hover:underline font-bold flex items-center gap-1">
                          + Add Method <ArrowRight size={12} />
                        </Link>
                      )}
                    </div>

                    {activeMethodOptions.length === 0 ? (
                      <div className="p-3 bg-amber-50 border border-amber-200/80 rounded-xl flex items-center justify-between text-amber-900 text-xs font-semibold">
                        <div className="flex items-center gap-2">
                          <AlertCircle size={16} className="text-amber-600 shrink-0" />
                          <span>No Payment Method found for this type.</span>
                        </div>
                        <Link href="/payment-methods" className="px-2.5 py-1 bg-amber-600 hover:bg-amber-700 text-white rounded-lg text-xs font-bold transition-all shrink-0">
                          Go to Methods
                        </Link>
                      </div>
                    ) : (
                      <Select value={formData.payment_method_id} onValueChange={(val) => setFormData({...formData, payment_method_id: val})}>
                        <SelectTrigger className="bg-white rounded-xl h-10 sm:h-11 text-xs sm:text-sm font-medium text-sunset-dark shadow-sm border-orange-500/50 hover:border-orange-500 focus:ring-orange-500/30">
                          <SelectValue placeholder="Select Method" />
                        </SelectTrigger>
                        <SelectContent className="z-[10050]">
                          {activeMethodOptions.map(m => <SelectItem key={m.id} value={String(m.id)}>{m.name}</SelectItem>)}
                        </SelectContent>
                      </Select>
                    )}
                    {errors.payment_method_id && <p className="text-xs text-red-500 mt-1 pl-1">{errors.payment_method_id[0]}</p>}
                  </div>

                </div>
              </div>
            </div>

            <div className="px-5 sm:px-8 py-4 sm:py-5 border-t border-sunset-primary/10 flex flex-row justify-end items-center gap-3 shrink-0 bg-gray-50/50 rounded-b-3xl sm:rounded-b-[2rem]">
              <Button variant="ghost" className="flex-1 sm:flex-none px-6 h-10 sm:h-11 text-xs sm:text-sm bg-white border shadow-sm" onClick={() => { setIsFormOpen(false); if(selectedDateStr) setIsRecordListOpen(true); }}>Cancel</Button>
              <Button 
                onClick={handleSave} 
                disabled={isSaving || activeCategoryOptions.length === 0 || activeMethodOptions.length === 0} 
                className="flex-1 sm:flex-none px-6 sm:px-8 h-10 sm:h-11 text-xs sm:text-sm flex items-center justify-center shadow-md text-white bg-orange-500 hover:bg-orange-600 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isSaving && <Loader2 className="w-4 h-4 animate-spin mr-2 shrink-0" />}
                {isSaving ? "Saving..." : "Save Record"}
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* 3. Delete Confirmation Modal */}
      {deletingRecord && (
        <div className="fixed inset-0 z-[10000] flex items-center justify-center p-4 sm:p-6 pb-20 md:pb-6 bg-sunset-dark/40 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white w-full max-w-lg rounded-3xl sm:rounded-[2rem] shadow-2xl flex flex-col animate-in zoom-in-95 duration-200 overflow-hidden">
            <div className="px-5 sm:px-8 py-5 sm:py-6 border-b border-sunset-primary/10 flex justify-between items-center shrink-0">
              <h2 className="text-lg sm:text-xl font-bold text-red-600">Delete Record</h2>
              <button onClick={() => setDeletingRecord(null)} className="p-2 bg-gray-50 hover:bg-gray-100 rounded-full text-gray-500 transition-colors">
                <X size={20} />
              </button>
            </div>
            <div className="p-5 sm:p-8 flex-1 overflow-y-auto">
              <p className="font-medium text-sunset-dark text-sm sm:text-base mb-6">Are you sure you want to delete this record? This action cannot be undone.</p>
              <div className="p-4 sm:p-5 bg-red-50 text-red-700 rounded-2xl sm:rounded-[1.5rem] border border-red-100 font-medium text-center">
                <span className="block text-[10px] sm:text-xs uppercase tracking-widest font-bold opacity-50 mb-1">{deletingRecord?.title} ({deletingRecord?.type})</span>
                <span className="text-3xl sm:text-4xl font-black block mt-2 tracking-tight">RM {formatPrice(deletingRecord?.price)}</span>
              </div>
            </div>
            <div className="px-5 sm:px-8 py-4 sm:py-5 border-t border-sunset-primary/10 flex flex-row justify-end items-center gap-3 bg-gray-50/50 rounded-b-3xl sm:rounded-b-[2rem] shrink-0">
              <Button variant="ghost" onClick={() => setDeletingRecord(null)} className="flex-1 sm:flex-none text-xs sm:text-sm h-10 sm:h-11 border bg-white shadow-sm">Cancel</Button>
              <Button variant="danger" onClick={handleDelete} className="flex-1 sm:flex-none text-xs sm:text-sm h-10 sm:h-11 shadow-md">Delete</Button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}