import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { responseApi } from '../api/responses';

export const useResponses = (ticketId: string) =>
  useQuery({
    queryKey: ['responses', ticketId],
    queryFn:  () => responseApi.getByTicket(ticketId),
    enabled:  !!ticketId,
  });

export const useAddResponse = (ticketId: string) => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: { ticketId: string; body: string; isInternal?: boolean }) =>
      responseApi.add(data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['responses', ticketId] }),
  });
};
