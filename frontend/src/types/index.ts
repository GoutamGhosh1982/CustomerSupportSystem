export interface User {
  userId:   string;
  fullName: string;
  email:    string;
  role:     'Customer' | 'Agent' | 'Supervisor' | 'Admin';
  token:    string;
}

export interface Ticket {
  id:             string;
  ticketNumber:   string;
  title:          string;
  description:    string;
  status:         TicketStatus;
  priority:       TicketPriority;
  category:       string;
  customerId:     string;
  customerName:   string;
  customerEmail:  string;
  assignedToId?:  string;
  assignedToName?:string;
  slaDeadline?:   string;
  createdAt:      string;
  updatedAt:      string;
  closedAt?:      string;
}

export type TicketStatus   = 'Open' | 'InProgress' | 'Escalated' | 'Closed';
export type TicketPriority = 'Low' | 'Medium' | 'High' | 'Critical';

export interface Response {
  id:          string;
  ticketId:    string;
  authorId:    string;
  authorName:  string;
  authorEmail: string;
  authorType:  'Customer' | 'Agent';
  body:        string;
  isInternal:  boolean;
  createdAt:   string;
  attachments: Attachment[];
}

export interface Attachment {
  id:            string;
  responseId:    string;
  fileName:      string;
  blobUrl:       string;
  contentType:   string;
  fileSizeBytes: number;
  uploadedAt:    string;
}

export interface PagedResult<T> {
  items:      T[];
  total:      number;
  page:       number;
  pageSize:   number;
  totalPages: number;
}

export interface CreateTicketRequest {
  title:       string;
  description: string;
  category:    string;
  priority:    TicketPriority;
}

export interface UpdateStatusRequest {
  status: TicketStatus;
  note?:  string;
}

export interface AssignTicketRequest {
  agentId:    string;
  agentName:  string;
  agentEmail: string;
}

export interface TicketFilters {
  status?:   string;
  priority?: string;
  category?: string;
  agentId?:  string;
  page?:     number;
  pageSize?: number;
}
