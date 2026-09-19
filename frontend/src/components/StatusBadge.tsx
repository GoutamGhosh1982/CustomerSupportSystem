import clsx from 'clsx';
import type { TicketStatus, TicketPriority } from '../types';

export const StatusBadge = ({ status }: { status: TicketStatus }) => {
  const classes: Record<TicketStatus, string> = {
    Open:       'badge-open',
    InProgress: 'badge-inprogress',
    Escalated:  'badge-escalated',
    Closed:     'badge-closed',
  };
  return (
    <span className={clsx(classes[status])}>
      {status === 'InProgress' ? 'In Progress' : status}
    </span>
  );
};

export const PriorityBadge = ({ priority }: { priority: TicketPriority }) => {
  const classes: Record<TicketPriority, string> = {
    Low:      'badge-low',
    Medium:   'badge-medium',
    High:     'badge-high',
    Critical: 'badge-critical',
  };
  return <span className={clsx(classes[priority])}>{priority}</span>;
};
