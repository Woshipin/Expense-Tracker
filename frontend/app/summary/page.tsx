"use client";

import { Card, Button, Input } from "@/components/ui";
import { Sparkles, Calendar as CalendarIcon, Send, Bot, User } from "lucide-react";
import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from "recharts";
import { useState, useRef, useEffect } from "react";
import Markdown from "react-markdown";

const areaData = [
  { name: 'W1', expense: 120, income: 800, budget: 150 },
  { name: 'W2', expense: 80, income: 0, budget: 150 },
  { name: 'W3', expense: 150, income: 0, budget: 150 },
  { name: 'W4', expense: 220, income: 450, budget: 150 },
];

const categoryData = [
  { name: 'Food', value: 480, color: '#FF7B42' },
  { name: 'Transport', value: 300, color: '#4CAF50' },
  { name: 'Entertainment', value: 120, color: '#FFCA28' },
];

export default function SummaryPage() {
  const [messages, setMessages] = useState<{role: 'user'|'model', text: string}[]>([
    { role: 'model', text: 'Hi! I am your AI Financial Assistant. I am analyzing your spending patterns for this month. You seem to be doing great on transport, but grocery spending is higher. How can I help you today?' }
  ]);
  const [input, setInput] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const chatEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSendMessage = async () => {
    if (!input.trim() || isLoading) return;
    
    const userMessage = { role: 'user' as const, text: input.trim() };
    setMessages(prev => [...prev, userMessage]);
    setInput("");
    setIsLoading(true);

    try {
      const response = await fetch('/api/summary-chat', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          messages: [...messages, userMessage],
          dataContext: {
            areaData,
            categoryData,
            netBalance: 2400,
            totalIncome: 4250,
            totalExpense: 1850,
          }
        }),
      });

      if (response.ok) {
        const data = await response.json();
        setMessages(prev => [...prev, { role: 'model', text: data.text }]);
      } else {
        setMessages(prev => [...prev, { role: 'model', text: "Sorry, I am having trouble connecting to my brain right now. Please try again later." }]);
      }
    } catch (error) {
      setMessages(prev => [...prev, { role: 'model', text: "Oops! A network error occurred." }]);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="space-y-6 animate-in fade-in zoom-in-95 duration-300 pb-8">
      <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-sunset-dark">Summary</h1>
          <p className="text-sm font-medium text-sunset-dark/60 mt-1">Deep dive into your financial health.</p>
        </div>
        <div className="flex items-center gap-2">
           <div className="flex items-center bg-white border border-sunset-primary/10 rounded-2xl p-1 shadow-sm overflow-x-auto">
             <input type="date" defaultValue="2023-10-01" className="bg-transparent text-sm font-bold text-sunset-dark outline-none px-3 py-1" />
             <span className="text-sunset-dark/40 font-bold">-</span>
             <input type="date" defaultValue="2023-10-31" className="bg-transparent text-sm font-bold text-sunset-dark outline-none px-3 py-1" />
           </div>
        </div>
      </header>

      {/* Hero Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
         <Card className="bg-sunset-primary/5 border-sunset-primary/10 shadow-none">
            <span className="text-[10px] uppercase font-bold tracking-widest text-sunset-dark/60">Total Income</span>
            <div className="mt-2 text-2xl font-black text-green-600">RM 4,250.00</div>
         </Card>
         <Card className="bg-sunset-primary/5 border-sunset-primary/10 shadow-none">
            <span className="text-[10px] uppercase font-bold tracking-widest text-sunset-dark/60">Total Expense</span>
            <div className="mt-2 text-2xl font-black text-red-500">RM 1,850.00</div>
         </Card>
         <Card className="bg-sunset-primary/5 border-sunset-primary/10 shadow-none">
            <span className="text-[10px] uppercase font-bold tracking-widest text-sunset-dark/60">Net Balance</span>
            <div className="mt-2 text-2xl font-black text-sunset-dark">RM 2,400.00</div>
         </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <Card className="lg:col-span-2 shadow-md shadow-black/5 flex flex-col min-h-[350px]">
          <h3 className="font-bold text-sunset-dark mb-6">Cashflow Overview</h3>
          <div className="flex-1 w-full relative">
            <ResponsiveContainer width="100%" height="100%" minHeight={250}>
              <AreaChart data={areaData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <defs>
                  <linearGradient id="colorExpense" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#ef4444" stopOpacity={0.2}/>
                    <stop offset="95%" stopColor="#ef4444" stopOpacity={0}/>
                  </linearGradient>
                  <linearGradient id="colorIncome" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#22c55e" stopOpacity={0.2}/>
                    <stop offset="95%" stopColor="#22c55e" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#2D1B14', opacity: 0.5 }} dy={10} />
                <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#2D1B14', opacity: 0.5 }} dx={-10} />
                <Tooltip 
                  contentStyle={{ borderRadius: '16px', border: '1px solid rgba(255,123,66,0.1)', boxShadow: '0 10px 15px -3px rgba(0,0,0,0.1)' }}
                  itemStyle={{ color: '#2D1B14', fontWeight: 600 }}
                  labelStyle={{ color: '#2D1B14', opacity: 0.5, fontWeight: 700, marginBottom: '4px' }}
                />
                <Area type="monotone" dataKey="income" stroke="#22c55e" strokeWidth={3} fillOpacity={1} fill="url(#colorIncome)" name="Income (RM)" />
                <Area type="monotone" dataKey="expense" stroke="#ef4444" strokeWidth={3} fillOpacity={1} fill="url(#colorExpense)" name="Expense (RM)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </Card>

        {/* Category Breakdown */}
        <Card className="shadow-md shadow-black/5 flex flex-col">
          <h3 className="font-bold text-sunset-dark mb-4">Category Spending</h3>
          <div className="flex-1 flex flex-col justify-center">
             <div className="h-[200px] w-full relative mb-6">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie data={categoryData} cx="50%" cy="50%" innerRadius={50} outerRadius={80} paddingAngle={2} dataKey="value" stroke="none">
                      {categoryData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                    </Pie>
                    <Tooltip formatter={(v:any) => `RM ${v}`} wrapperClassName="rounded-xl overflow-hidden shadow-xl border-none" contentStyle={{border: 'none'}} />
                  </PieChart>
                </ResponsiveContainer>
             </div>
             <div className="space-y-4">
                {categoryData.map(c => (
                   <div key={c.name}>
                      <div className="flex justify-between text-sm mb-1 line-clamp-1 truncate">
                         <span className="font-bold text-sunset-dark/70 flex items-center gap-2"><div className="w-2 h-2 rounded-full" style={{background: c.color}}></div>{c.name}</span>
                         <span className="font-black text-sunset-dark">RM {c.value}</span>
                      </div>
                      <div className="w-full h-1.5 bg-black/5 rounded-full overflow-hidden">
                         <div className="h-full rounded-full" style={{width: `${(c.value/900)*100}%`, backgroundColor: c.color}}></div>
                      </div>
                   </div>
                ))}
             </div>
          </div>
        </Card>
      </div>

      {/* AI Insights Chat Panel */}
      <div className="mt-8">
        <h3 className="font-bold text-sunset-dark flex items-center gap-2 mb-4"><Sparkles className="text-sunset-primary" size={20} /> AI Financial Assistant</h3>
        <Card className="p-0 overflow-hidden shadow-md shadow-black/5 border-sunset-primary/10 flex flex-col relative bg-white min-h-[600px] h-full h-[600px]">
           
           {/* Top: 3D Interactive Placeholder */}
           <div className="h-[200px] bg-sunset-bg relative flex flex-col items-center justify-center p-6 border-b border-sunset-primary/10 shrink-0">
               <div className="absolute inset-0 overflow-hidden pointer-events-none opacity-30">
                 <div className="absolute -top-16 -left-16 w-32 h-32 bg-sunset-primary blur-[50px] rounded-full mix-blend-multiply"></div>
                 <div className="absolute top-1/2 right-1/4 w-48 h-48 bg-sunset-primary blur-[80px] rounded-full mix-blend-multiply opacity-50"></div>
               </div>
               
               <div className="text-center relative z-10 w-full flex flex-col items-center">
                  {/* 3D blob simulation */}
                  <div className="w-16 h-16 bg-gradient-to-tr from-sunset-primary to-orange-400 rounded-2xl animate-[spin_10s_linear_infinite] shadow-[0_0_30px_rgba(255,123,66,0.4)] mb-4" style={{borderRadius: '40% 60% 70% 30% / 40% 50% 60% 50%'}}></div>
                  <p className="font-bold text-lg text-sunset-dark mb-1">Interactive Financial Engine Active</p>
                  <p className="text-xs font-medium text-sunset-dark/50">Analyzing real-time transaction data</p>
               </div>
           </div>

           {/* Chat History */}
           <div className="flex-1 overflow-y-auto p-4 md:p-6 space-y-6">
              {messages.map((msg, index) => (
                <div key={index} className={`flex gap-4 ${msg.role === 'user' ? 'flex-row-reverse' : ''}`}>
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center shrink-0 ${msg.role === 'user' ? 'bg-sunset-primary text-white' : 'bg-sunset-primary/10 text-sunset-primary'}`}>
                    {msg.role === 'user' ? <User size={16} /> : <Bot size={16} />}
                  </div>
                  <div className={`p-4 rounded-2xl max-w-[85%] sm:max-w-[75%] ${msg.role === 'user' ? 'bg-sunset-primary text-white rounded-tr-sm' : 'bg-sunset-bg border border-sunset-primary/10 text-sunset-dark rounded-tl-sm shadow-sm'}`}>
                    {msg.role === 'user' ? (
                      <p className="text-sm font-medium">{msg.text}</p>
                    ) : (
                      <div className="text-sm font-medium leading-relaxed markdown-body">
                         <Markdown>{msg.text}</Markdown>
                      </div>
                    )}
                  </div>
                </div>
              ))}
              {isLoading && (
                <div className="flex gap-4">
                  <div className="w-8 h-8 rounded-full bg-sunset-primary/10 text-sunset-primary flex items-center justify-center shrink-0"><Bot size={16} /></div>
                  <div className="p-4 rounded-2xl bg-sunset-bg border border-sunset-primary/10 text-sunset-dark/60 rounded-tl-sm flex items-center gap-1.5 h-[52px]">
                    <span className="w-1.5 h-1.5 rounded-full bg-sunset-primary animate-bounce"></span>
                    <span className="w-1.5 h-1.5 rounded-full bg-sunset-primary animate-bounce delay-100"></span>
                    <span className="w-1.5 h-1.5 rounded-full bg-sunset-primary animate-bounce delay-200"></span>
                  </div>
                </div>
              )}
              <div ref={chatEndRef} />
           </div>

           {/* Chat Input */}
           <div className="p-4 border-t border-sunset-primary/10 bg-white shrink-0">
             <form onSubmit={(e) => { e.preventDefault(); handleSendMessage(); }} className="relative flex items-center">
               <Input 
                 placeholder="Ask about your budget, savings advice, or financial tips..."
                 className="w-full pl-4 pr-12 h-12 bg-sunset-bg/50 border-sunset-primary/20 rounded-xl focus:ring-2 focus:ring-sunset-primary/30"
                 value={input}
                 onChange={(e) => setInput(e.target.value)}
                 disabled={isLoading}
               />
               <button type="submit" disabled={isLoading || !input.trim()} className="absolute right-1.5 h-9 w-9 p-0 flex items-center justify-center rounded-lg bg-sunset-primary text-white hover:bg-sunset-dark transition-colors border-none shadow-none disabled:opacity-50 disabled:cursor-not-allowed">
                 <Send size={16} />
               </button>
             </form>
           </div>
        </Card>
      </div>
    </div>
  );
}
