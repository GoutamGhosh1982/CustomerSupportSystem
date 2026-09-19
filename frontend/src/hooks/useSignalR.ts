import { useEffect, useRef } from 'react';
import { HubConnectionBuilder, HubConnection, LogLevel } from '@microsoft/signalr';
import { useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';

export const useSignalR = (ticketId?: string) => {
  const qc         = useQueryClient();
  const connRef    = useRef<HubConnection | null>(null);

  useEffect(() => {
    const token = localStorage.getItem('token');
    if (!token) return;

    const conn = new HubConnectionBuilder()
      .withUrl('/hubs/notifications', {
        accessTokenFactory: () => token
      })
      .withAutomaticReconnect()
      .configureLogging(LogLevel.Warning)
      .build();

    conn.on('TicketCreated', (evt) => {
      toast.success(`New ticket: ${evt.title}`);
      qc.invalidateQueries({ queryKey: ['tickets'] });
    });

    conn.on('TicketUpdated', (evt) => {
      toast.info(`Ticket ${evt.ticketNumber} → ${evt.newStatus}`);
      qc.invalidateQueries({ queryKey: ['tickets'] });
      if (ticketId) qc.invalidateQueries({ queryKey: ['ticket', ticketId] });
    });

    conn.on('TicketAssigned', (evt) => {
      toast.info(`Ticket ${evt.ticketNumber} assigned`);
      qc.invalidateQueries({ queryKey: ['tickets'] });
    });

    conn.on('ResponseAdded', () => {
      if (ticketId) qc.invalidateQueries({ queryKey: ['responses', ticketId] });
    });

    conn.start()
      .then(async () => {
        await conn.invoke('JoinGroup', 'agents');
        if (ticketId) await conn.invoke('JoinGroup', `ticket-${ticketId}`);
      })
      .catch(console.error);

    connRef.current = conn;

    return () => {
      conn.stop();
    };
  }, [ticketId, qc]);

  return connRef;
};
