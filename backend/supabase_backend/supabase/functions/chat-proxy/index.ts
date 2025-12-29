import { serve } from "https://deno.land/std@0.177.0/http/server.ts"

const OPENROUTER_KEY = Deno.env.get("OPENROUTER_API_KEY")!
const SERVICE_KEY = Deno.env.get("SERVICE_ROLE_KEY")!
const PROJECT_URL = Deno.env.get("PROJECT_URL")!

serve(async (req) => {
  try {
    const { message, user_id = "anonymous" } = await req.json()
    const userMessage = message?.toString().trim()
    
    if (!userMessage) {
      return new Response(
        JSON.stringify({ error: "No message provided" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      )
    }

    // ---------- CHILD SAFETY MODERATION ----------
    const bannedWords = ["sex", "porn", "nude", "kill", "suicide", "rape", "drugs", "alcohol"]
    const flagged = bannedWords.some(word => userMessage.toLowerCase().includes(word))

    if (flagged) {
      await fetch(`${PROJECT_URL}/rest/v1/moderation_logs`, {
        method: "POST",
        headers: {
          "apikey": SERVICE_KEY,
          "Authorization": `Bearer ${SERVICE_KEY}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          user_input: userMessage,
          reason: "Child safety filter"
        })
      })

      return new Response(
        JSON.stringify({
          reply: "I’m here to help keep you safe 😊 Please talk to a trusted adult."
        }),
        { headers: { "Content-Type": "application/json" } }
      )
    }

    // ---------- OPENROUTER CALL ----------
    const systemPrompt = `
You are a child-safe assistant.
Never provide sexual, violent, or harmful content.
Encourage safety, kindness, and trusted adults.
`

    const aiRes = await fetch("https://openrouter.ai/api/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${OPENROUTER_KEY}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model: "google/gemma-3-27b-it:free",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userMessage }
        ]
      })
    })

    const aiData = await aiRes.json()

    // ---------- SAFETY CHECK ----------
    if (!aiRes.ok || !aiData.choices || !aiData.choices[0]) {
      console.error("OpenRouter error:", aiData)
      return new Response(
        JSON.stringify({ error: "AI service failed", details: aiData }),
        { status: 502, headers: { "Content-Type": "application/json" } }
      )
    }

    const reply = aiData.choices[0].message.content

    // ---------- LOG CHAT TO SUPABASE ----------
    await fetch(`${PROJECT_URL}/rest/v1/chats`, {
      method: "POST",
      headers: {
        "apikey": SERVICE_KEY,
        "Authorization": `Bearer ${SERVICE_KEY}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify([
        { user_id, role: "user", content: userMessage },
        { user_id, role: "assistant", content: reply }
      ])
    })

    // ---------- RETURN AI RESPONSE ----------
    return new Response(
      JSON.stringify({ reply }),
      { headers: { "Content-Type": "application/json" } }
    )

  } catch (err) {
    console.error("Function error:", err)
    return new Response(
      JSON.stringify({ error: "Internal Server Error", details: err.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }
})
