import React, { useState, useEffect } from "react";
import { supabase } from "../../Supabase/supabaseClient";
import { useNavigate } from "react-router-dom";
import "../../Style/Profile.css";
import Sidebar from "../Sidebar";
import { FiUpload, FiSettings, FiTrash } from "react-icons/fi";
import Notifications from "../Notifications";

function Profile({ adminUser }) {
  const navigate = useNavigate();
  const effectiveId = adminUser?.admin_id ?? 1; // fallback id 1
  const adminName = adminUser?.username ?? "Admin"; // fallback name "Admin"

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
        {/* ✅ Header */}
        <div className="profile-header">
          <div>
            <h2 className="profile-title">Profile</h2>
            <div className="profile-subtitle">
              Here you have the basic information
            </div>
          </div>

          <div className="profile-header-actions">
            {/* Notifications */}
            <div className="notification-wrapper">
              <Notifications />
            </div>

            {/* Settings */}
            <div className="settings-wrapper">
              <FiSettings
                size={22}
                className="settings-icon"
                onClick={() => navigate("/settings")}
              />
            </div>

            {/* Profile Avatar */}
            <div className="dropdown-wrapper">
              <img
                src={form.profile_img || "https://via.placeholder.com/32"}
                alt="profile"
                className="profile-avatar"
                onClick={() => navigate("/profile")}
              />
            </div>
          </div>
        </div>

        {/* ✅ Profile Account Section */}
        <div className="profile-account">
          <div className="profile-left">
            {form.profile_img && (
              <img
                src={form.profile_img}
                alt="Avatar"
                className="profile-main-avatar"
              />
            )}
            <div className="profile-account-info">
              <div className="profile-account-name">{form.username || "Admin"}</div>
              <div className="profile-account-email">{form.email}</div>
            </div>
          </div>

          <button
            className="btn"
            onClick={() => document.querySelector("#avatarInput").click()}
          >
            <FiUpload /> Upload New Avatar
          </button>
          <input
            id="avatarInput"
            type="file"
            accept="image/*"
            onChange={handleFileUpload}
            style={{ display: "none" }}
          />
        </div>

        {/* Name */}
        <div className="profile-name">
          <div className="gap">
            <span className="profile-name-label">Name </span>
            <div className="register-name">{adminName}</div>
          </div>
          <button className="name-edit" onClick={() => setEditMode(true)}>
            Edit Profile
          </button>
        </div>

        {/* Email */}

        <div className="profile-email">
          <div className="gap">
            <span className="profile-name-label">Email </span>
            <div className="register-name">{form.email}</div>
          </div>
          <button className="name-edit" onClick={() => setEditMode(true)}>
            Edit Email
          </button>
        </div>

        {/* Password */}
        <div className="profile-password">
          <div className="gap">
            <span className="profile-name-label">Password </span>
            <div className="register-name">********</div>
          </div>
          <button className="name-edit" onClick={() => setEditMode(true)}>
            Edit Password
          </button>
        </div>

        {/* Account Security */}
        <div className="profile-account-security">
          <div className="gap">
            <span className="profile-name-label">Account Security </span>
            <div className="profile-account-security-text">Manage your Account Security</div>
            <div className="delete-btn">
              <FiTrash 
              className="profile-account-security-trash-icon"/>
              <span>Delete Account</span>
            </div>
          </div>
        </div>

        {/* Read-only */}
        {/* {!editMode && (
          <div className="card">
            <h3>Account Details</h3>
            {form.profile_img && (
              <img
                src={form.profile_img}
                alt="Avatar"
                className="avatar-preview"
              />
            )}
            <p>
              <strong>Username:</strong> {form.username}
            </p>
            <p>
              <strong>Password:</strong> ******
            </p>
            <p>
              <strong>Email:</strong> {form.email}
            </p>
            <p>
              <strong>Phone Number:</strong> {form.phone_number}
            </p>
            <button className="btn" onClick={() => setEditMode(true)}>
              ✏️ Edit Profile
            </button>
          </div>
        )} */}

        {/* Editable */}
        {/* {editMode && (
          <div className="profile-main">
            <h3>Edit Profile</h3>
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
            <div className="form-group">
              <label>Username</label>
              <input
                type="text"
                value={form.username}
                onChange={(e) =>
                  setForm({ ...form, username: e.target.value })
                }
              />
            </div>
            <div className="form-group">
              <label>Password</label>
              <input
                type="password"
                value={form.password}
                onChange={(e) =>
                  setForm({ ...form, password: e.target.value })
                }
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
                onChange={(e) =>
                  setForm({ ...form, phone_number: e.target.value })
                }
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

        {message && <p className="message">{message}</p>} */}
      </div>
    </div>
  );
}

export default Profile;
