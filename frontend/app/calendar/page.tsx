"use client";

import { Card, Button, Modal, Toast, Input } from "@/components/ui";
import { ChevronLeft, ChevronRight, Plus, Edit2, Trash2 } from "lucide-react";
import { useState } from "react";

const PAYMENT_METHODS = ['Credit Card', 'Debit Card', 'TNG', 'Cash', 'Online Transfer', 'Online Pay', 'Other Pay'];

export default function CalendarPage() {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const [selectedDate, setSelectedDate] = useState<number | null>(null);
  
  // Modals
  const [isRecordListOpen, setIsRecordListOpen] = useState(false);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingRecord, setEditingRecord] = useState<any>(null);
  const [formType, setFormType] = useState<'expense'|'income'>('expense');
  const [toast, setToast] = useState<{message:string, type:'success'|'error'|'warning'}|null>(null);

  const showToast = (msg: string, t: 'success'|'error'|'warning' = 'success') => {
    setToast({ message: msg, type: t });
    setTimeout(() => setToast(null), 3000);
  };

  const dayRecords = [
    { id: 1, type: 'expense', title: 'Coffee', price: 15.50, time: '08:30' },
    { id: 2, type: 'income', title: 'Freelance', price: 850.00, time: '14:00' },
  ];

  const handleDayClick = (dayNum: number) => {
    setSelectedDate(dayNum);
    setIsRecordListOpen(true);
  };

  const handleDelete = (id: number) => {
    showToast('Record deleted successfully', 'success');
  };

  const openForm = (record: any = null) => {
    setEditingRecord(record);
    setFormType(record?.type || 'expense');
    setIsFormOpen(true);
  };

  const handleSave = () => {
    setIsFormOpen(false);
    showToast(editingRecord ? 'Record updated' : 'Record added successfully', 'success');
  };

  return (
    <div className="space-y-6 animate-in fade-in zoom-in-95 duration-300">
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
      
      <header className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-sunset-dark">Calendar</h1>
          <p className="text-sm font-medium text-sunset-dark/60 mt-1">Review your transactions day-by-day.</p>
        </div>
      </header>

      <Card className="p-4 md:p-6 shadow-md overflow-hidden bg-white/80">
        <div className="flex items-center justify-between mb-8">
          <h2 className="text-xl font-bold text-sunset-dark">October 2023</h2>
          <div className="flex gap-2">
            <button className="p-2 rounded-xl border border-sunset-primary/10 hover:bg-sunset-primary/5 transition-colors"><ChevronLeft size={20} /></button>
            <button className="p-2 rounded-xl border border-sunset-primary/10 hover:bg-sunset-primary/5 transition-colors"><ChevronRight size={20} /></button>
          </div>
        </div>

        <div className="grid grid-cols-7 gap-1 md:gap-2 mb-2">
          {days.map(day => (
            <div key={day} className="text-center text-[10px] sm:text-xs font-bold text-sunset-dark/40 uppercase tracking-widest truncate">{day}</div>
          ))}
        </div>
        
        <div className="grid grid-cols-7 gap-1 md:gap-2">
          {Array.from({ length: 31 }).map((_, i) => {
            const dateNum = i + 1;
            const hasExpense = dateNum === 14 || dateNum === 25;
            const hasIncome = dateNum === 23 || dateNum === 25;
            
            return (
              <div 
                key={i} 
                onClick={() => handleDayClick(dateNum)}
                className={`min-h-[70px] md:min-h-[100px] rounded-xl sm:rounded-2xl border transition-colors relative flex flex-col pt-6 sm:pt-8 pb-1 px-1 sm:px-2 cursor-pointer hover:border-sunset-primary active:scale-95 ${dateNum === 23 ? 'bg-sunset-primary/10 border-sunset-primary text-sunset-dark shadow-sm' : 'bg-white border-sunset-primary/10 shadow-sm group hover:shadow-md'}`}
              >
                <span className={`text-sm sm:text-base font-bold absolute top-1 sm:top-2 left-1.5 sm:left-2 ${dateNum === 23 ? 'text-sunset-primary' : 'text-sunset-dark/70 group-hover:text-sunset-primary'}`}>{dateNum}</span>
                
                {hasExpense && <div className="mt-auto hidden sm:block truncate text-[10px] sm:text-xs font-bold bg-red-50 text-red-600 px-1.5 sm:px-2 py-0.5 sm:py-1 rounded-md sm:rounded-lg -mx-0.5 mb-1 text-right">Exp</div>}
                {hasIncome && <div className={`${hasExpense ? '' : 'mt-auto'} hidden sm:block truncate text-[10px] sm:text-xs font-bold bg-green-50 text-green-600 px-1.5 sm:px-2 py-0.5 sm:py-1 rounded-md sm:rounded-lg -mx-0.5 text-right`}>Inc</div>}
                
                {/* Mobile tiny dot indicators */}
                <div className="absolute bottom-2 flex gap-1 justify-center w-full left-0 sm:hidden">
                  {hasExpense && <div className="w-1.5 h-1.5 rounded-full bg-red-500" />}
                  {hasIncome && <div className="w-1.5 h-1.5 rounded-full bg-green-500" />}
                </div>
              </div>
            );
          })}
        </div>
      </Card>

      {/* Date Overview Modal */}
      <Modal isOpen={isRecordListOpen} onClose={() => setIsRecordListOpen(false)} title={`Transactions on Oct ${selectedDate}, 2023`}>
        <div className="space-y-4">
           {dayRecords.map(r => (
             <div key={r.id} className="flex justify-between items-center p-3 sm:p-4 rounded-2xl border border-sunset-primary/10 bg-sunset-bg/30">
               <div>
                 <p className="font-bold text-sunset-dark text-base">{r.title}</p>
                 <p className="text-xs font-medium text-sunset-dark/50">{r.time} • {r.type.toUpperCase()}</p>
               </div>
               <div className="flex items-center gap-3 sm:gap-4">
                 <span className={`font-black text-lg ${r.type === 'income' ? 'text-green-600' : 'text-red-500'}`}>
                   {r.type === 'income' ? '+' : '-'}RM {r.price.toFixed(2)}
                 </span>
                 <div className="flex gap-1 bg-white p-1 rounded-xl shadow-sm border border-sunset-primary/5">
                   <button onClick={() => openForm(r)} className="p-2 rounded-lg text-sunset-dark/50 hover:text-blue-500 hover:bg-blue-50"><Edit2 size={16}/></button>
                   <button onClick={() => handleDelete(r.id)} className="p-2 rounded-lg text-sunset-dark/50 hover:text-red-500 hover:bg-red-50"><Trash2 size={16}/></button>
                 </div>
               </div>
             </div>
           ))}
           <div className="pt-4 border-t border-sunset-primary/5 flex gap-3 flex-col sm:flex-row">
             <Button variant="secondary" onClick={() => setIsRecordListOpen(false)} className="w-full sm:w-auto">Close</Button>
             <Button onClick={() => openForm()} className="w-full flex-1"><Plus size={16} className="mr-2 inline"/> Add New Record</Button>
           </div>
        </div>
      </Modal>

      {/* Add / Edit Shared Form Modal inside Calendar */}
      <Modal isOpen={isFormOpen} onClose={() => setIsFormOpen(false)} title={editingRecord ? "Edit Record" : "Add Record"}>
        <div className="space-y-4">
          <div className="flex bg-sunset-bg/50 p-1 rounded-2xl mb-4">
            <button type="button" onClick={(e) => {e.stopPropagation(); setFormType('expense');}} className={`flex-1 py-2 rounded-xl text-sm font-bold shadow-sm border ${formType === 'expense' ? 'bg-white border-sunset-primary/10 text-sunset-dark' : 'border-transparent text-sunset-dark/40 hover:text-sunset-dark'}`}>Expense</button>
            <button type="button" onClick={(e) => {e.stopPropagation(); setFormType('income');}} className={`flex-1 py-2 rounded-xl text-sm font-bold shadow-sm border ${formType === 'income' ? 'bg-white border-sunset-primary/10 text-sunset-dark' : 'border-transparent text-sunset-dark/40 hover:text-sunset-dark'}`}>Income</button>
          </div>
          <div><label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">Title</label><Input placeholder="Title" defaultValue={editingRecord?.title} /></div>
          <div><label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">Amount (RM)</label><Input type="number" placeholder="0.00" defaultValue={editingRecord?.price} /></div>
          <div className="grid grid-cols-2 gap-4">
             <div><label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">Category</label><Input placeholder="Category" /></div>
             <div>
                <label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">Method</label>
                <select className="w-full bg-sunset-bg/50 border border-sunset-primary/10 rounded-2xl px-4 py-3 outline-none text-sunset-dark font-medium transition-shadow appearance-none">
                  {PAYMENT_METHODS.map(m => (<option key={m}>{m}</option>))}
                </select>
             </div>
          </div>
          <div className="flex flex-col sm:flex-row justify-end pt-4 gap-3">
             <Button variant="ghost" onClick={() => setIsFormOpen(false)}>Cancel</Button>
             <Button onClick={handleSave}>Save Record</Button>
          </div>
        </div>
      </Modal>

    </div>
  );
}
