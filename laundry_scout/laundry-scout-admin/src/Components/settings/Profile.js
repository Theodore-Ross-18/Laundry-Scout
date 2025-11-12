import React, { useState, useEffect } from "react";
import { supabase } from "../../Supabase/supabaseClient";
import { useNavigate } from "react-router-dom";
import "../../Style/Profile.css";
import Sidebar from "../Sidebar";
import { FiUpload, FiSettings, FiTrash, FiUser } from "react-icons/fi";
import Notifications from "../Notifications";

function Profile({ adminUser }) {
  const navigate = useNavigate();
  const effectiveId = adminUser?.admin_id ?? 1;
  const adminName = adminUser?.username ?? "Admin";

  const [form, setForm] = useState({
    username: "",
    password: "",
    email: "",
    phone_number: "",
    profile_img: "",
  });

  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("");
  const [editField, setEditField] = useState(null); // 🔑 which field to edit
  const [sidebarOpen, setSidebarOpen] = useState(true);

  // ✅ fetch admin data
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

  // ✅ upload new avatar
  const handleFileUpload = async (e) => {
    if (!editField) return;
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

  // ✅ save changes
  const handleSave = async () => {
    if (!effectiveId) {
      setMessage("❌ Admin ID not available yet.");
      return;
    }

    setLoading(true);

    // Only update the field being edited
    const updates = { [editField]: form[editField] };

    const { error: updateError } = await supabase
      .from("admin")
      .update(updates)
      .eq("admin_id", effectiveId);

    setLoading(false);

    if (updateError) {
      setMessage("❌ Save failed: " + updateError.message);
    } else {
      setMessage("✅ " + editField + " updated successfully!");
      setEditField(null);
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
            <div className="notification-wrapper">
              <Notifications />
            </div>
            <div className="settings-wrapper">
              <FiSettings
                size={22}
                className="settings-icon"
                onClick={() => navigate("/settings")}
              />
            </div>
            <div className="dropdown-wrapper">
              <FiUser
                size={32}

                className="profile-avatar"
                onClick={() => navigate("/profile")}
              />
            </div>
          </div>
        </div>

        {/* ✅ Profile Account Section */}
        <div className="profile-account">
          <div className="profile-left">
            {form.profile_img ? (
              <img
                src={form.profile_img}
                alt="Avatar"
                className="profile-main-avatar"
              />

            ) : (
              <FiUser size={100} className="profile-main-avatar" />
            )}
            <div className="profile-account-info">
              <div className="profile-account-name">
                {form.username || "Admin"}
              </div>
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
            <div className="register-name">{form.username}</div>
          </div>
          <button className="name-edit" onClick={() => setEditField("username")}>
            Edit Name
          </button>
        </div>

        {/* Email */}
        <div className="profile-email">
          <div className="gap">
            <span className="profile-name-label">Email </span>
            <div className="register-name">{form.email}</div>
          </div>
          <button className="name-edit" onClick={() => setEditField("email")}>
            Edit Email
          </button>
        </div>

        {/* Password */}
        <div className="profile-password">
          <div className="gap">
            <span className="profile-name-label">Password </span>
            <div className="register-name">********</div>
          </div>
          <button className="name-edit" onClick={() => setEditField("password")}>
            Edit Password
          </button>
        </div>

        {/* Account Security */}
        <div className="profile-account-security">
          <div className="gap">
            <span className="profile-name-label">Account Security </span>
            <div className="profile-account-security-text">
              Manage your Account Security
            </div>
            <div className="delete-btn">
              <FiTrash className="profile-account-security-trash-icon" />
              <span>Delete Account</span>
            </div>
          </div>
        </div>

        {/* ✅ Overlay Modal for Editing */}
        {editField && (
          <div className="overlay">
            <div className="overlay-content">
              <h3>Edit {editField.charAt(0).toUpperCase() + editField.slice(1)}</h3>

              <div className="form-group">
                <label>{editField}</label>
                <input
                  type={editField === "password" ? "password" : "text"}
                  value={form[editField]}
                  onChange={(e) =>
                    setForm({ ...form, [editField]: e.target.value })
                  }
                />
              </div>

              <div className="form-actions">
                <button
                  className="btn primary"
                  onClick={handleSave}
                  disabled={loading}
                >
                  {loading ? "Saving..." : "Save"}
                </button>
                <button className="btn secondary" onClick={() => setEditField(null)}>
                  Cancel
                </button>
              </div>

              {message && <p className="message">{message}</p>}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

export default Profile;
