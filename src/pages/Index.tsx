import { Link } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/contexts/AuthContext";
import { Zap, ArrowRight, Shield, Brain, CreditCard } from "lucide-react";

export default function Index() {
  const { user } = useAuth();

  const features = [
    { icon: Brain, title: "AI-Powered Matching", desc: "Smart algorithms connect the right developer to every task" },
    { icon: Shield, title: "Trust & Security", desc: "Skill tests, fraud detection, and reputation scoring built in" },
    { icon: CreditCard, title: "Escrow Payments", desc: "Secure payments held until work is completed and approved" },
  ];

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
          <div className="flex items-center gap-3">
            {user ? (
              <Button asChild size="sm">
                <Link to="/dashboard">Dashboard <ArrowRight className="ml-1 h-3.5 w-3.5" /></Link>
              </Button>
            ) : (
              <>
                <Button variant="ghost" size="sm" asChild>
                  <Link to="/auth">Log in</Link>
                </Button>
                <Button size="sm" asChild>
                  <Link to="/auth">Get Started</Link>
                </Button>
              </>
            )}
          </div>
        </div>
      </header>

      <main>
        <section className="mx-auto max-w-6xl px-4 py-24 text-center">
          <div className="mx-auto max-w-2xl">
            <div className="mb-4 inline-flex items-center gap-1.5 rounded-full border border-border bg-muted px-3 py-1 text-xs font-medium text-muted-foreground">
              <Zap className="h-3 w-3" /> AI-Managed Platform
            </div>
            <h1 className="text-4xl font-bold tracking-tight text-foreground sm:text-5xl">
              Connect problems to solutions, intelligently
            </h1>
            <p className="mt-4 text-lg text-muted-foreground">
              An AI operations manager that understands tasks, matches developers, ensures trust, and controls quality — from ticket to delivery.
            </p>
            <div className="mt-8 flex justify-center gap-3">
              <Button size="lg" asChild>
                <Link to="/auth">Start Free <ArrowRight className="ml-1 h-4 w-4" /></Link>
              </Button>
            </div>
          </div>
        </section>

        <section className="border-t border-border bg-muted/30">
          <div className="mx-auto grid max-w-6xl gap-8 px-4 py-20 sm:grid-cols-3">
            {features.map((f) => (
              <div key={f.title} className="space-y-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10">
                  <f.icon className="h-5 w-5 text-primary" />
                </div>
                <h3 className="font-semibold text-foreground">{f.title}</h3>
                <p className="text-sm leading-relaxed text-muted-foreground">{f.desc}</p>
              </div>
            ))}
          </div>
        </section>
      </main>

      <footer className="border-t border-border py-8 text-center text-sm text-muted-foreground">
        © 2026 Ticket AI. All rights reserved.
      </footer>
    </div>
  );
}
