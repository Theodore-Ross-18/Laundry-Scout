// deleteUser.js (Backend API Route)
import express from "express";
import fetch from "node-fetch";

const router = express.Router();

router.delete("/:id", async (req, res) => {
  const { id } = req.params;

  try {
    const response = await fetch(
      `https://YOUR_PROJECT.supabase.co/auth/v1/admin/users/${id}`,
      {
        method: "DELETE",
        headers: {
          apiKey: process.env.SUPABASE_SERVICE_ROLE_KEY,
          Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
        },
      }
    );

    if (!response.ok) {
      return res.status(400).json({ error: "Failed to delete user from Auth" });
    }

    return res.json({ success: true });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

export default router;
