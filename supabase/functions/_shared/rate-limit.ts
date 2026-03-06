
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

export async function checkRateLimit(
    supabase: SupabaseClient,
    key: string,
    limit: number,
    windowSeconds: number
): Promise<{ blocked: boolean; resetTime?: Date }> {
    try {
        const now = new Date();
        const windowStartThreshold = new Date(now.getTime() - windowSeconds * 1000);

        // 1. Get existing record
        const { data: record, error } = await supabase
            .from("rate_limits")
            .select("*")
            .eq("key", key)
            .single();

        if (error && error.code !== "PGRST116") {
            // Log error but fail open (don't block if DB is down)
            console.error("Rate limit fetch error:", error);
            return { blocked: false };
        }

        if (!record) {
            // 2. Insert new
            await supabase.from("rate_limits").insert({
                key,
                count: 1,
                window_start: now.toISOString(),
            });
            return { blocked: false };
        }

        const windowStart = new Date(record.window_start);

        if (windowStart < windowStartThreshold) {
            // 3. Reset window if expired
            await supabase.from("rate_limits").update({
                count: 1,
                window_start: now.toISOString(),
            }).eq("key", key);
            return { blocked: false };
        }

        // 4. Check limit
        if (record.count >= limit) {
            return {
                blocked: true,
                resetTime: new Date(windowStart.getTime() + windowSeconds * 1000),
            };
        }

        // 5. Increment
        await supabase.from("rate_limits").update({
            count: record.count + 1,
        }).eq("key", key);

        return { blocked: false };
    } catch (err) {
        console.error("Rate limit unexpected error:", err);
        return { blocked: false };
    }
}
