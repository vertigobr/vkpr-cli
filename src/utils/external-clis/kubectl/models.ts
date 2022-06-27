export interface Pod {
  name: string,
	labels: Record<string, unknown>,
	namespace: string
}

export interface Secret {
  name: string,
	labels: Record<string, unknown>,
	namespace: string
	data: Record<string, unknown>
}

export interface Namespace {
  name: string
}

export interface Status {
  status: string | undefined,
  message?: string
  reason?: string
}

