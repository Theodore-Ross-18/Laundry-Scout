import React, { useState, useEffect } from "react";
import { supabase } from "../../Supabase/supabaseClient";
import { useNavigate } from "react-router-dom";
import "../../Style/Profile.css";
import Sidebar from "../Sidebar";
function Profile({ adminUser }) {
  const navigate = useNavigate();
  const effectiveId = adminUser?.admin_id ?? 1; // fallback id 1

  const [form, setForm] = useState({
    username: "",
    password: "",
    email: "",
    phone_number: "",
    profile_img: "",
  });

  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("");
  const [editMode, setEditMode] = useState(false);
  const [sidebarOpen, setSidebarOpen] = useState(true);

  // ✅ fetch admin data from Supabase on mount or id change
  useEffect(() => {
    if (!effectiveId) return;
    (async () => {
      const { data, error } = await supabase
        .from("admin")
        .select("*")
        .eq("admin_id", effectiveId)
        .single();

      if (error) {
        setMessage("❌ Unable to fetch admin info: " + error.message);
      } else if (data) {
        setForm({
          username: data.username || "",
          password: data.password || "",
          email: data.email || "",
          phone_number: data.phone_number || "",
          profile_img: data.profile_img || "",
        });
      }
    })();
  }, [effectiveId]);

  // upload new avatar
  const handleFileUpload = async (e) => {
    if (!editMode) return;
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
      setForm((prev) => ({ ...prev, profile_img: data.publicUrl }));
      setMessage("✅ Profile picture uploaded!");
    }
  };

  // save changes
  const handleSave = async () => {
    if (!effectiveId) {
      setMessage("❌ Admin ID not available yet.");
      return;
    }

    setLoading(true);
    const { error: updateError } = await supabase
      .from("admin")
      .update({
        username: form.username,
        password: form.password,
        email: form.email,
        phone_number: form.phone_number,
        profile_img: form.profile_img,
      })
      .eq("admin_id", effectiveId);

    setLoading(false);

    if (updateError) {
      setMessage("❌ Save failed: " + updateError.message);
    } else {
      setMessage("✅ Profile updated successfully!");
      setEditMode(false);
      setTimeout(() => setMessage(""), 2000);
    }
  };

  return (
    <div className="profile-root">
      <Sidebar isOpen={sidebarOpen} />
      <div className="profile-main">
        <button className="btn" onClick={() => navigate(-1)}>⬅ Back</button>
        <h2>👤 Admin Profile</h2>

        {/* Read-only */}
        {!editMode && (
          <div className="card">
            <h3>Account Details</h3>
            {form.profile_img && (
              <img src={form.profile_img} alt="Avatar" className="avatar-preview" />
            )}
            <p><strong>Username:</strong> {form.username}</p>
            <p><strong>Password:</strong> ******</p>
            <p><strong>Email:</strong> {form.email}</p>
            <p><strong>Phone Number:</strong> {form.phone_number}</p>
            <button className="btn" onClick={() => setEditMode(true)}>
              ✏️ Edit Profile
            </button>
          </div>
        )}

        {/* Editable */}
        {editMode && (
          <div className="profile-main">
            <h3>Edit Profile</h3>
            <div className="form-group">
              <label>Profile Picture</label>
              <input type="file" accept="image/*" onChange={handleFileUpload} />
              {form.profile_img && (
                <img src={form.profile_img} alt="Avatar" className="avatar-preview" />
              )}
            </div>
            <div className="form-group">
              <label>Username</label>
              <input
                type="text"
                value={form.username}
                onChange={(e) => setForm({ ...form, username: e.target.value })}
              />
            </div>
            <div className="form-group">
              <label>Password</label>
              <input
                type="password"
                value={form.password}
                onChange={(e) => setForm({ ...form, password: e.target.value })}
              />
            </div>
            <div className="form-group">
              <label>Email</label>
              <input
                type="email"
                value={form.email}
                onChange={(e) => setForm({ ...form, email: e.target.value })}
              />
            </div>
            <div className="form-group">
              <label>Phone Number</label>
              <input
                type="text"
                value={form.phone_number}
                onChange={(e) => setForm({ ...form, phone_number: e.target.value })}
              />
            </div>

            <div className="form-actions">
              <button
                className="btn primary"
                onClick={handleSave}
                disabled={loading}
              >
                {loading ? "Saving..." : "Save Changes"}
              </button>
              <button
                className="btn secondary"
                onClick={() => setEditMode(false)}
              >
                Cancel
              </button>
            </div>
          </div>
        )}

        {message && <p className="message">{message}</p>}
      </div>
      
    </div>
  );
}

export default Profile;
