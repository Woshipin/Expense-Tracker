"use client";

import { Card, Button, Modal, Toast, Input } from "@/components/ui";
import { Plus, Edit2, Trash2 } from "lucide-react";
import { useState } from "react";

export default function BudgetPage() {
  const [toast, setToast] = useState<{message:string, type:'success'|'error'|'warning'}|null>(null);
  const [isAddOpen, setIsAddOpen] = useState(false);
  const [editingBudget, setEditingBudget] = useState<any>(null);
  const [deletingBudget, setDeletingBudget] = useState<any>(null);

  const [budgets, setBudgets] = useState([
    { id: 1, name: 'Monthly Food', category: 'Groceries', spent: 480, total: 500, start: '2023-10-01', end: '2023-10-31' },
    { id: 2, name: 'Weekend Fun', category: 'Entertainment', spent: 120, total: 200, start: '2023-10-01', end: '2023-10-31' },
    { id: 3, name: 'Transport Pass', category: 'Transport', spent: 80, total: 400, start: '2023-10-01', end: '2023-10-31' },
  ]);

  const showToast = (message: string, type: 'success'|'error'|'warning' = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  const handleSave = () => {
    setIsAddOpen(false);
    setEditingBudget(null);
    showToast(editingBudget ? 'Budget updated successfully!' : 'Budget created successfully!', 'success');
  };

  const handleDelete = () => {
    setBudgets(budgets.filter(b => b.id !== deletingBudget.id));
    setDeletingBudget(null);
    showToast('Budget deleted', 'success');
  };

  return (
    <div className="space-y-6 animate-in fade-in zoom-in-95 duration-300">
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
      
      {/* Create / Edit Modal */}
      <Modal isOpen={isAddOpen || !!editingBudget} onClose={() => { setIsAddOpen(false); setEditingBudget(null); }} title={editingBudget ? "Edit Budget" : "Create Budget"}>
        <div className="space-y-4">
          <div><label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">Budget Name</label><Input placeholder="E.g., Monthly Food" defaultValue={editingBudget?.name} /></div>
          <div><label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">Category</label><Input placeholder="E.g., Groceries" defaultValue={editingBudget?.category} /></div>
          <div><label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">Limit Amount (RM)</label><Input placeholder="0.00" type="number" defaultValue={editingBudget?.total} /></div>
          <div className="grid grid-cols-2 gap-4">
             <div><label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">Start Date</label><Input type="date" defaultValue={editingBudget?.start} /></div>
             <div><label className="text-xs font-bold text-sunset-dark/70 uppercase tracking-widest pl-2 mb-2 block">End Date</label><Input type="date" defaultValue={editingBudget?.end} /></div>
          </div>
          <div className="flex flex-col sm:flex-row justify-end pt-4 gap-3">
            <Button variant="ghost" onClick={() => { setIsAddOpen(false); setEditingBudget(null); }}>Cancel</Button>
            <Button onClick={handleSave}>Save Budget</Button>
          </div>
        </div>
      </Modal>

      {/* Delete Confirmation Modal */}
      <Modal isOpen={!!deletingBudget} onClose={() => setDeletingBudget(null)} title="Delete Budget">
        <div className="space-y-4">
          <p className="font-medium text-sunset-dark">Are you sure you want to delete this budget? All tracking history will be kept, but the limit warning will be removed.</p>
          <div className="p-4 bg-red-50 text-red-700 rounded-2xl border border-red-100 font-medium pb-2">
            <span className="block text-sm uppercase tracking-widest font-bold opacity-50 mb-1">Deleting budget limit:</span>
            {deletingBudget?.name} <br/>
            <span className="text-2xl font-black block mt-2">RM {deletingBudget?.total?.toFixed(2)}</span>
          </div>
          <div className="flex flex-col sm:flex-row justify-end pt-4 gap-3">
            <Button variant="ghost" onClick={() => setDeletingBudget(null)}>Cancel</Button>
            <Button variant="danger" onClick={handleDelete}>Delete Permanently</Button>
          </div>
        </div>
      </Modal>

      <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
           <h1 className="text-2xl font-bold text-sunset-dark">Budget</h1>
           <p className="text-sm font-medium text-sunset-dark/60 mt-1">Control and set limits to your spending behavior.</p>
        </div>
        <Button onClick={() => setIsAddOpen(true)}><Plus size={16} className="mr-2 inline" /> Create Budget</Button>
      </header>

      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
        {budgets.map(b => {
          const percentage = (b.spent / b.total) * 100;
          const remaining = b.total - b.spent;
          const isWarning = percentage > 80;
          
          return (
            <Card key={b.id} className={`shadow-md flex flex-col ${isWarning ? 'border-red-500/30' : 'border-sunset-primary/10 hover:border-sunset-primary/30'} transition-colors`}>
              <div className="flex justify-between items-start mb-6">
                <div>
                  <h3 className="font-bold text-sunset-dark text-lg leading-tight">{b.name}</h3>
                  <span className="inline-block mt-2 px-2 py-1 bg-black/5 text-sunset-dark/60 text-[10px] uppercase tracking-widest font-bold rounded-md">{b.category}</span>
                </div>
                <div className="flex gap-1 bg-white p-1 rounded-xl shadow-sm border border-sunset-primary/5">
                   <button onClick={() => setEditingBudget(b)} className="p-2 text-sunset-dark/40 hover:text-blue-500 hover:bg-blue-50 rounded-lg transition-colors"><Edit2 size={16}/></button>
                   <button onClick={() => setDeletingBudget(b)} className="p-2 text-sunset-dark/40 hover:text-red-500 hover:bg-red-50 rounded-lg transition-colors"><Trash2 size={16}/></button>
                </div>
              </div>
              
              <div className="mt-auto">
                 <div className="flex justify-between items-baseline mb-2">
                    <span className="text-sm font-bold text-sunset-dark/50">Spent RM {b.spent.toFixed(2)}</span>
                    <span className={`text-xl font-black ${isWarning ? 'text-red-500' : 'text-sunset-dark'}`}>{Math.round(percentage)}%</span>
                 </div>
                 <div className="h-4 w-full bg-black/5 rounded-full overflow-hidden shadow-inner">
                    <div className={`h-full rounded-full transition-all duration-1000 ${isWarning ? 'bg-red-500' : 'bg-sunset-primary'}`} style={{ width: `${Math.min(percentage, 100)}%` }} />
                 </div>
                 <div className="mt-3 flex justify-between items-center text-xs font-bold text-sunset-dark/60">
                    <span>Limit: RM {b.total.toFixed(2)}</span>
                    <span className={isWarning ? 'text-red-500' : ''}>Remaining: RM {remaining.toFixed(2)}</span>
                 </div>
              </div>
            </Card>
          );
        })}
      </div>
    </div>
  );
}
