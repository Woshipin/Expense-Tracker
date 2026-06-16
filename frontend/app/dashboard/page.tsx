"use client";

import { Card, Button, Toast } from "@/components/ui";
import { Plus } from "lucide-react";
import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from "recharts";
import { useState } from "react";
import { useRouter } from "next/navigation";

const areaData = [
  { name: 'Mon', expense: 120, income: 0 },
  { name: 'Tue', expense: 80, income: 400 },
  { name: 'Wed', expense: 150, income: 0 },
  { name: 'Thu', expense: 220, income: 0 },
  { name: 'Fri', expense: 350, income: 1200 },
  { name: 'Sat', expense: 90, income: 0 },
  { name: 'Sun', expense: 50, income: 0 },
];

const pieData = [
  { name: 'Food', value: 400, color: '#FF7B42' },
  { name: 'Transport', value: 300, color: '#4CAF50' },
  { name: 'Shopping', value: 300, color: '#FFCA28' },
];

export default function DashboardPage() {
  const router = useRouter();
  const [toast, setToast] = useState<{message:string, type:'success'|'error'|'warning'}|null>(null);

  const handleAction = (msg: string) => {
    setToast({ message: msg, type: 'success' });
  };

  return (
    <div className="space-y-6 animate-in fade-in zoom-in-95 duration-300">
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
      
      <header className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-sunset-dark">Dashboard</h1>
        </div>
        <div className="w-10 h-10 rounded-full bg-sunset-primary/10 text-sunset-primary flex items-center justify-center font-bold">
          AC
        </div>
      </header>

      {/* Main Balance Card */}
      <Card className="bg-gradient-to-br from-sunset-primary to-sunset-secondary text-white border-none p-6 md:p-8 shadow-xl shadow-sunset-primary/20 relative overflow-hidden">
        <div className="absolute top-0 right-0 w-64 h-64 bg-white/10 rounded-full blur-3xl -mr-16 -mt-16 pointer-events-none"></div>
        <div className="absolute bottom-0 right-24 w-32 h-32 bg-black/10 rounded-full blur-2xl mb-8 pointer-events-none"></div>
        
        <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-6 relative z-10 w-full min-w-0">
          <div className="flex-1 min-w-0">
            <p className="text-white/80 text-xs font-bold uppercase tracking-widest mb-2 truncate">Net Balance</p>
            <h2 className="text-4xl md:text-5xl font-bold tracking-tight leading-none truncate mb-4 sm:mb-0 max-w-full">RM 12,450.00</h2>
          </div>
          <div className="flex flex-wrap sm:flex-nowrap items-center gap-3 shrink-0">
            <Button variant="secondary" className="px-4 py-2 text-sm h-auto bg-white/20 text-white hover:bg-white/30 truncate flex-1 sm:flex-none border-none" onClick={() => router.push('/income')}>
              <Plus size={16} className="mr-1.5 inline" /> Income
            </Button>
            <Button variant="ghost" className="bg-sunset-dark text-white hover:bg-sunset-dark/90 px-4 py-2 text-sm h-auto border-none truncate flex-1 sm:flex-none" onClick={() => router.push('/expenses')}>
               <Plus size={16} className="mr-1.5 inline" /> Expense
            </Button>
          </div>
        </div>

        <div className="flex gap-4 sm:gap-12 mt-8 lg:mt-10 pt-6 border-t border-white/20">
          <div className="min-w-0 flex-1">
            <p className="text-white/80 text-[10px] sm:text-[10px] font-bold uppercase tracking-widest mb-1 truncate">Total Income (This Month)</p>
            <div className="flex items-center gap-2 flex-wrap">
              <span className="text-xl sm:text-2xl font-bold truncate">RM 4,250.00</span>
            </div>
          </div>
          <div className="min-w-0 flex-1 border-l border-white/20 pl-4 sm:pl-12">
            <p className="text-white/80 text-[10px] sm:text-[10px] font-bold uppercase tracking-widest mb-1 truncate">Total Expenses</p>
            <div className="flex items-center gap-2 flex-wrap">
              <span className="text-xl sm:text-2xl font-bold truncate">RM 1,850.00</span>
            </div>
          </div>
        </div>
      </Card>

      {/* Analytics & Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <Card className="lg:col-span-2 shadow-md shadow-black/5 flex flex-col">
          <div className="flex items-center justify-between mb-6 shrink-0">
            <h3 className="font-bold text-sunset-dark">Monthly Trend</h3>
            <select className="bg-sunset-bg/50 border border-sunset-primary/10 rounded-xl px-3 py-1.5 text-xs font-bold text-sunset-primary focus:outline-none outline-none appearance-none cursor-pointer">
              <option>Oct 1 - Oct 31</option>
              <option>Sep 1 - Sep 30</option>
            </select>
          </div>
          <div className="flex-1 w-full min-h-[250px]">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={areaData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <defs>
                  <linearGradient id="colorExpense" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#ef4444" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="#ef4444" stopOpacity={0}/>
                  </linearGradient>
                  <linearGradient id="colorIncome" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#22c55e" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="#22c55e" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#2D1B14', opacity: 0.5 }} dy={10} />
                <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#2D1B14', opacity: 0.5 }} dx={-10} />
                <Tooltip 
                  contentStyle={{ borderRadius: '16px', border: '1px solid rgba(255,123,66,0.1)', boxShadow: '0 10px 15px -3px rgba(0,0,0,0.1)' }}
                  itemStyle={{ color: '#2D1B14', fontWeight: 600 }}
                  formatter={(value: any, name: any) => [`RM ${value}`, String(name).charAt(0).toUpperCase() + String(name).slice(1)]}
                />
                <Area type="monotone" dataKey="income" stroke="#22c55e" strokeWidth={3} fillOpacity={1} fill="url(#colorIncome)" />
                <Area type="monotone" dataKey="expense" stroke="#ef4444" strokeWidth={3} fillOpacity={1} fill="url(#colorExpense)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </Card>

        <Card className="shadow-md shadow-black/5 flex flex-col">
          <h3 className="font-bold text-sunset-dark mb-4">Top Categories</h3>
          <div className="flex-1 flex flex-col justify-center">
            <div className="h-[180px] w-full relative">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={pieData}
                    cx="50%"
                    cy="50%"
                    innerRadius={60}
                    outerRadius={80}
                    paddingAngle={5}
                    dataKey="value"
                    stroke="none"
                  >
                    {pieData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip formatter={(v:any) => `RM ${v}`} wrapperClassName="rounded-xl overflow-hidden" contentStyle={{ border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}/>
                </PieChart>
              </ResponsiveContainer>
              <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                <span className="text-[10px] uppercase font-bold tracking-widest text-sunset-dark/40 pb-0.5">Budget Usage</span>
                <span className="text-xl font-bold text-sunset-primary leading-none">65%</span>
              </div>
            </div>
            <div className="mt-4 space-y-3">
              {pieData.map((item) => (
                <div key={item.name} className="flex items-center justify-between text-sm">
                  <div className="flex items-center gap-2">
                    <div className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: item.color }} />
                    <span className="font-bold text-sunset-dark/70">{item.name}</span>
                  </div>
                  <span className="font-black text-sunset-dark">RM {item.value}</span>
                </div>
              ))}
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
}
