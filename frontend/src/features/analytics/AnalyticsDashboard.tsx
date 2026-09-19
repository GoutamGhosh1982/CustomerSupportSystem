import { useTickets } from '../../hooks/useTickets';
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend
} from 'recharts';

const STATUS_COLORS: Record<string, string> = {
  Open:       '#f59e0b',
  InProgress: '#3b82f6',
  Escalated:  '#ef4444',
  Closed:     '#22c55e',
};

export default function AnalyticsDashboard() {
  const { data: openData }     = useTickets({ status: 'Open',       pageSize: 1000 });
  const { data: progressData } = useTickets({ status: 'InProgress', pageSize: 1000 });
  const { data: escalData }    = useTickets({ status: 'Escalated',  pageSize: 1000 });
  const { data: closedData }   = useTickets({ status: 'Closed',     pageSize: 1000 });

  const statusData = [
    { name: 'Open',        value: openData?.total      ?? 0 },
    { name: 'In Progress', value: progressData?.total  ?? 0 },
    { name: 'Escalated',   value: escalData?.total     ?? 0 },
    { name: 'Closed',      value: closedData?.total    ?? 0 },
  ];

  const totalOpen   = openData?.total     ?? 0;
  const totalClosed = closedData?.total   ?? 0;
  const totalAll    = statusData.reduce((s, d) => s + d.value, 0);

  // Category breakdown from open tickets
  const catMap: Record<string, number> = {};
  openData?.items.forEach(t => { catMap[t.category] = (catMap[t.category] ?? 0) + 1; });
  const categoryData = Object.entries(catMap).map(([cat, count]) => ({ category: cat, count }))
                             .sort((a, b) => b.count - a.count);

  const KPI = ({ label, value, sub }: { label: string; value: string | number; sub?: string }) => (
    <div className="card text-center">
      <div className="text-3xl font-bold text-blue-700">{value}</div>
      <div className="text-sm font-medium text-gray-700 mt-1">{label}</div>
      {sub && <div className="text-xs text-gray-400 mt-0.5">{sub}</div>}
    </div>
  );

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Analytics Dashboard</h1>

      {/* KPIs */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        <KPI label="Total Tickets"   value={totalAll}    />
        <KPI label="Open Tickets"    value={totalOpen}   sub="Awaiting action" />
        <KPI label="Escalated"       value={escalData?.total ?? 0} sub="High urgency" />
        <KPI label="Resolved"        value={totalClosed} sub="Successfully closed" />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Status Pie */}
        <div className="card">
          <h2 className="font-semibold text-gray-800 mb-4">Tickets by Status</h2>
          <ResponsiveContainer width="100%" height={250}>
            <PieChart>
              <Pie data={statusData} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={80} label>
                {statusData.map((entry, i) => (
                  <Cell key={i} fill={Object.values(STATUS_COLORS)[i]} />
                ))}
              </Pie>
              <Tooltip />
              <Legend />
            </PieChart>
          </ResponsiveContainer>
        </div>

        {/* Category Bar */}
        <div className="card">
          <h2 className="font-semibold text-gray-800 mb-4">Open Tickets by Category</h2>
          {categoryData.length === 0 ? (
            <p className="text-gray-400 text-sm text-center py-8">No open tickets.</p>
          ) : (
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={categoryData} margin={{ left: -20 }}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="category" tick={{ fontSize: 11 }} />
                <YAxis allowDecimals={false} />
                <Tooltip />
                <Bar dataKey="count" fill="#3b82f6" radius={[4,4,0,0]} />
              </BarChart>
            </ResponsiveContainer>
          )}
        </div>
      </div>
    </div>
  );
}
