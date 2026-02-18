"use client";

import { useEffect, useState } from "react";
import Link from "next/link";

interface AgentData {
  id: string;
  title: string;
  domain: string;
  reports_to: string;
  responsibilities: string[];
  expected_inputs: string[];
  expected_outputs: string[];
  token_cap: number;
}

interface AgentRegistry {
  chiefs: AgentData[];
  tech: AgentData[];
  marketing: AgentData[];
  personas: string[];
  total: number;
}

export default function AgentsPage() {
  const [data, setData] = useState<AgentRegistry | null>(null);
  const [filter, setFilter] = useState<"all" | "chiefs" | "tech" | "marketing">("all");
  const [search, setSearch] = useState("");
  const [expanded, setExpanded] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch("/api/orchestrator/agents")
      .then((r) => r.json())
      .then((d) => {
        setData(d);
        setLoading(false);
      });
  }, []);

  if (loading || !data) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-gray-500">Loading agents...</div>
      </div>
    );
  }

  const allAgents: { agent: AgentData; category: string }[] = [
    ...data.chiefs.map((a) => ({ agent: a, category: "chiefs" })),
    ...data.tech.map((a) => ({ agent: a, category: "tech" })),
    ...data.marketing.map((a) => ({ agent: a, category: "marketing" })),
  ];

  const filtered = allAgents.filter((item) => {
    if (filter !== "all" && item.category !== filter) return false;
    if (search) {
      const q = search.toLowerCase();
      return (
        item.agent.id.toLowerCase().includes(q) ||
        item.agent.title.toLowerCase().includes(q) ||
        item.agent.domain?.toLowerCase().includes(q) ||
        item.agent.responsibilities?.some((r) => r.toLowerCase().includes(q))
      );
    }
    return true;
  });

  const categoryColors: Record<string, string> = {
    chiefs: "bg-purple-100 text-purple-700",
    tech: "bg-blue-100 text-blue-700",
    marketing: "bg-orange-100 text-orange-700",
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white border-b border-gray-200 px-6 py-4">
        <div className="max-w-7xl mx-auto">
          <div className="flex items-center gap-2 text-sm text-gray-500 mb-2">
            <Link href="/orchestrator" className="hover:text-gray-900">
              Orchestrator
            </Link>
            <span>/</span>
            <span className="text-gray-900">Agent Registry</span>
          </div>
          <h1 className="text-2xl font-bold text-gray-900">
            Agent Registry ({data.total} agents)
          </h1>
          <p className="text-sm text-gray-500 mt-1">
            {data.chiefs.length} chiefs · {data.tech.length} tech specialists ·{" "}
            {data.marketing.length} marketing specialists · {data.personas.length}{" "}
            personas
          </p>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-6 py-6">
        {/* Controls */}
        <div className="flex flex-wrap gap-3 mb-6">
          <input
            type="text"
            placeholder="Search agents..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="px-4 py-2 bg-white border rounded-lg text-sm w-64 focus:ring-2 focus:ring-blue-200 focus:border-blue-400 outline-none"
          />
          <div className="flex gap-1">
            {(["all", "chiefs", "tech", "marketing"] as const).map((f) => (
              <button
                key={f}
                onClick={() => setFilter(f)}
                className={`px-3 py-2 text-sm rounded-lg font-medium transition-colors ${
                  filter === f
                    ? "bg-gray-900 text-white"
                    : "bg-white text-gray-600 hover:bg-gray-100 border"
                }`}
              >
                {f === "all"
                  ? `All (${allAgents.length})`
                  : `${f.charAt(0).toUpperCase() + f.slice(1)} (${
                      f === "chiefs"
                        ? data.chiefs.length
                        : f === "tech"
                        ? data.tech.length
                        : data.marketing.length
                    })`}
              </button>
            ))}
          </div>
        </div>

        {/* Results */}
        <div className="text-sm text-gray-500 mb-3">
          Showing {filtered.length} agent{filtered.length !== 1 ? "s" : ""}
        </div>

        <div className="space-y-2">
          {filtered.map(({ agent, category }) => (
            <div
              key={agent.id}
              className="bg-white border rounded-lg overflow-hidden"
            >
              <button
                onClick={() =>
                  setExpanded(expanded === agent.id ? null : agent.id)
                }
                className="w-full text-left p-4 flex items-center gap-4 hover:bg-gray-50 transition-colors"
              >
                <span
                  className={`text-xs font-medium px-2 py-0.5 rounded-full ${categoryColors[category]}`}
                >
                  {category}
                </span>
                <div className="flex-1">
                  <span className="font-medium text-gray-900">
                    {agent.title}
                  </span>
                  <span className="text-xs text-gray-400 ml-2">
                    {agent.id}
                  </span>
                </div>
                <span className="text-xs text-gray-400">
                  {agent.domain || "—"}
                </span>
                <span className="text-gray-400">
                  {expanded === agent.id ? "▴" : "▾"}
                </span>
              </button>

              {expanded === agent.id && (
                <div className="border-t px-4 py-4 bg-gray-50 space-y-3 text-sm">
                  {agent.reports_to && (
                    <div>
                      <span className="font-medium text-gray-700">
                        Reports to:
                      </span>{" "}
                      <span className="text-gray-600">{agent.reports_to}</span>
                    </div>
                  )}
                  {agent.responsibilities?.length > 0 && (
                    <div>
                      <div className="font-medium text-gray-700 mb-1">
                        Responsibilities:
                      </div>
                      <ul className="list-disc list-inside text-gray-600 space-y-0.5">
                        {agent.responsibilities.map((r, i) => (
                          <li key={i}>{r}</li>
                        ))}
                      </ul>
                    </div>
                  )}
                  <div className="flex gap-6 text-xs">
                    <div>
                      <span className="font-medium text-gray-700">Inputs:</span>{" "}
                      <span className="text-gray-500">
                        {agent.expected_inputs?.join(", ") || "—"}
                      </span>
                    </div>
                    <div>
                      <span className="font-medium text-gray-700">Outputs:</span>{" "}
                      <span className="text-gray-500">
                        {agent.expected_outputs?.join(", ") || "—"}
                      </span>
                    </div>
                    <div>
                      <span className="font-medium text-gray-700">Token cap:</span>{" "}
                      <span className="text-gray-500">
                        {agent.token_cap || "—"}
                      </span>
                    </div>
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>

        {/* Personas */}
        <div className="mt-10">
          <h2 className="text-lg font-bold text-gray-900 mb-3">
            Expert Personas ({data.personas.length})
          </h2>
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-2">
            {data.personas.map((p) => {
              const name = p
                .replace(".md", "")
                .replace(/-/g, " ")
                .replace(/\b\w/g, (c) => c.toUpperCase());
              return (
                <div
                  key={p}
                  className="bg-white border rounded-lg px-3 py-2 text-sm text-gray-700"
                >
                  {name}
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}
