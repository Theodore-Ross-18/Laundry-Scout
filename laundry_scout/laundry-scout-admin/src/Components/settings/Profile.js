// src/Components/settings/Profile.js
import React, { useState } from "react";
import { supabase } from "../../Supabase/supabaseClient";
import { useNavigate } from "react-router-dom";
import "../../Style/Admin.css";

function Profile({ adminUser }) {
  const isDefaultAdmin = !adminUser?.id; // no id = default login
  const navigate = useNavigate();

  // State for details + editing
  const [showEmailForm, setShowEmailForm] = useState(false);
  const [emailInput, setEmailInput] = useState(adminUser?.email || "");
  const [emailSent, setEmailSent] = useState(false);
  const [verified, setVerified] = useState(false);

  const [form, setForm] = useState({
    username: adminUser?.username || "",
    phone_number: adminUser?.phone_number || "",
    profile_img: adminUser?.profile_img || "",
  });

  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("");

  // --- Upload profile image ---
  const handleFileUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const filePath = `avatars/${Date.now()}_${file.name}`;
    const { error } = await supabase.storage
      .from("admin-avatars")
      .upload(filePath, file);

    if (error) {
      setMessage("❌ Upload failed: " + error.message);
    } else {
      const { data } = supabase.storage
        .from("admin-avatars")
        .getPublicUrl(filePath);
      setForm({ ...form, profile_img: data.publicUrl });
      setMessage("✅ Profile picture uploaded!");
    }
  };

  // --- Send verification OTP for email ---
  const sendVerificationLink = async () => {
    if (!emailInput) {
      setMessage("❌ Please enter an email.");
      return;
    }
    setLoading(true);

    const { error } = await supabase.auth.signInWithOtp({
      email: emailInput,
      options: { emailRedirectTo: window.location.origin },
    });

    setLoading(false);
    if (error) {
      setMessage("❌ Failed to send verification link: " + error.message);
    } else {
      setMessage("📩 Verification link sent to " + emailInput);
      setEmailSent(true);
    }
  };

  // --- Save profile changes (including verified email) ---
  const handleSave = async () => {
    if (showEmailForm && !verified) {
      setMessage("❌ Please verify your new email first.");
      return;
    }

    setLoading(true);
    let error;

    if (isDefaultAdmin) {
      const { error: insertError } = await supabase.from("admin").insert([
        {
          username: form.username,
          email: emailInput,
          phone_number: form.phone_number,
          profile_img: form.profile_img,
        },
      ]);
      error = insertError;
    } else {
      const { error: updateError } = await supabase
        .from("admin")
        .update({
          username: form.username,
          email: emailInput,
          phone_number: form.phone_number,
          profile_img: form.profile_img,
        })
        .eq("id", adminUser.id);
      error = updateError;
    }

    setLoading(false);
    if (error) {
      setMessage("❌ Save failed: " + error.message);
    } else {
      setMessage("✅ Profile updated successfully!");
      setTimeout(() => navigate("/dashboard"), 1500);
    }
  };

  return (
    <div className="page-container">
      <button className="btn" onClick={() => navigate(-1)}>
        ⬅ Back
      </button>
      <h2>👤 Admin Profile</h2>

      {/* --- Account Details --- */}
      <div className="card">
        <h3>Account Details</h3>

        {/* Avatar */}
        <div className="form-group">
          <label>Profile Picture</label>
          <input type="file" accept="image/*" onChange={handleFileUpload} />
          {form.profile_img && (
            <img
              src={form.profile_img}
              alt="Avatar"
              className="avatar-preview"
            />
          )}
        </div>

        <p><strong>Username:</strong> {form.username}</p>
        <p><strong>Email:</strong> {emailInput || "Not set"}</p>
        <p><strong>Phone:</strong> {form.phone_number || "Not set"}</p>

        {/* Change Email Button */}
        {!showEmailForm && (
          <button
            className="btn secondary"
            onClick={() => setShowEmailForm(true)}
          >
            ➕ Change / Add Email
          </button>
        )}
      </div>

      {/* --- Email Change Form --- */}
      {showEmailForm && (
        <div className="card">
          <h3>Update Email</h3>
          <div className="form-group">
            <label>New Email</label>
            <input
              type="email"
              value={emailInput}
              onChange={(e) => setEmailInput(e.target.value)}
              disabled={verified}
            />
          </div>

          {!emailSent && (
            <button
              className="btn primary"
              onClick={sendVerificationLink}
              disabled={loading}
            >
              {loading ? "Sending..." : "Send Verification Link"}
            </button>
          )}

          {emailSent && (
            <p className="message">
              📩 Check your inbox and click the link to verify your new email.
            </p>
          )}
        </div>
      )}

      {/* --- Save Button --- */}
      <div className="card">
        <button
          className="btn primary"
          onClick={handleSave}
          disabled={loading}
        >
          {loading ? "Saving..." : "Save Profile"}
        </button>
      </div>

      {message && <p className="message">{message}</p>}
    </div>
  );
}

export default Profile;
