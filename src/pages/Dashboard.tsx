import { useAuth } from "@/contexts/AuthContext";
import { Button } from "@/components/ui/button";
import { LogOut, Zap } from "lucide-react";

export default function Dashboard() {
  const { profile, role, signOut } = useAuth();

  return (
    <div className="min-h-screen bg-background">
      <header className="border-b border-border">
        <div className="mx-auto flex h-14 max-w-6xl items-center justify-between px-4">
          <div className="flex items-center gap-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary">
              <Zap className="h-4 w-4 text-primary-foreground" />
            </div>
            <span className="font-semibold text-foreground">Ticket AI</span>
          </div>
          <div className="flex items-center gap-4">
            <span className="text-sm text-muted-foreground">
              {profile?.full_name || "User"} · <span className="capitalize">{role}</span>
            </span>
            <Button variant="ghost" size="icon" onClick={signOut}>
              <LogOut className="h-4 w-4" />
            </Button>
          </div>
        </div>
      </header>
      <main className="mx-auto max-w-6xl px-4 py-12">
        <h1 className="text-2xl font-semibold text-foreground">
          Welcome, {profile?.full_name || "there"}
        </h1>
        <p className="mt-2 text-muted-foreground">
          Your <span className="capitalize">{role}</span> dashboard is being built. More features coming soon.
        </p>
      </main>
    </div>
  );
}
