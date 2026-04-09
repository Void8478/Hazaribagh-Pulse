declare const Deno: {
  env: {
    get(name: string): string | undefined
  }
  serve(
    handler: (request: Request) => Response | Promise<Response>,
  ): void
}

declare module 'https://esm.sh/@supabase/supabase-js@2.57.4' {
  export interface SupabaseClient {
    schema(schema: string): {
      from(table: string): {
        select(columns: string): {
          eq(column: string, value: string): {
            like(
              column: string,
              pattern: string,
            ): Promise<{ data: Array<{ name: unknown }> | null; error: { message: string } | null }>
          }
        }
      }
    }
    storage: {
      from(bucket: string): {
        remove(
          paths: string[],
        ): Promise<{ error: { message: string } | null }>
      }
    }
    rpc(
      fn: string,
      args: Record<string, unknown>,
    ): Promise<{ data: unknown; error: { message: string } | null }>
    auth: {
      getUser(): Promise<{
        data: { user: { id: string } | null }
        error: { message: string } | null
      }>
      admin: {
        deleteUser(
          id: string,
          shouldSoftDelete?: boolean,
        ): Promise<{ error: { message: string } | null }>
      }
    }
  }

  export function createClient(
    url: string,
    key: string,
    options?: Record<string, unknown>,
  ): SupabaseClient
}
