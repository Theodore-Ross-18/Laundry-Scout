import React, { useEffect, useState } from "react";
import { supabase } from "../Supabase/supabaseClient";
import { FiBell } from "react-icons/fi";
import "../Style/Notifications.css";

function Notifications() {
  const [notifications, setNotifications] = useState([]);
  const [unread, setUnread] = useState(false);
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const [overlayOpen, setOverlayOpen] = useState(false);

  useEffect(() => {
    const fetchAllRegistrations = async () => {
      try {
        const { data: users } = await supabase
          .from("user_profiles")
          .select("id, username, email, created_at")
          .order("created_at", { ascending: false });

        const { data: businesses } = await supabase
          .from("business_profiles")
          .select("id, business_name, owner_first_name, owner_last_name, created_at")
          .order("created_at", { ascending: false });

        let all = [];

        if (users) {
          all.push(
            ...users.map((u) => ({
              id: `user-${u.id}`,
              type: "user",
              message: `New user registered: ${u.username || u.email}`,
              time: new Date(u.created_at).toLocaleString(),
            }))
          );
        }

        if (businesses) {
          all.push(
            ...businesses.map((b) => ({
              id: `business-${b.id}`,
              type: "business",
              message: `New business registered: ${b.business_name} (Owner: ${
                b.owner_first_name || ""} ${b.owner_last_name || ""})`,
              time: new Date(b.created_at).toLocaleString(),
            }))
          );
        }

        all.sort((a, b) => new Date(b.time) - new Date(a.time));
        setNotifications(all);
      } catch (err) {
        console.error("Error fetching notifications:", err.message);
      }
    };

    fetchAllRegistrations();
  }, []);

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = () => setDropdownOpen(false);
    document.addEventListener("click", handleClickOutside);
    return () => document.removeEventListener("click", handleClickOutside);
  }, []);

  return (
    <div className="notification-wrapper">
      {/* Bell Icon */}
      <div
        className="notification-bell"
        onClick={(e) => {
          e.stopPropagation();
          setDropdownOpen(!dropdownOpen);
          setUnread(false);
        }}
      >
        <FiBell size={22} />
        {unread && <span className="notification-dot" />}
      </div>

      {/* Small Dropdown (latest 5) */}
      {dropdownOpen && (
        <div
          className="notification-dropdown"
          onClick={(e) => e.stopPropagation()}
        >
          <div className="dropdown-header">Notifications</div>
          {notifications.length === 0 ? (
            <div className="dropdown-empty">No notifications yet</div>
          ) : (
            <>
              {notifications.slice(0, 5).map((note) => (
                <div key={note.id} className="dropdown-item">
                  <div className="note-message">{note.message}</div>
                  <div className="note-time">{note.time}</div>
                </div>
              ))}
              {notifications.length > 5 && (
                <button
                  className="show-all-btn"
                  onClick={() => {
                    setOverlayOpen(true);
                    setDropdownOpen(false);
                  }}
                >
                  Show All
                </button>
              )}
            </>
          )}
        </div>
      )}

      {/* Full Overlay for all notifications */}
      {overlayOpen && (
        <div className="notification-overlay">
          <div className="overlay-content">
            <div className="overlay-header">
              <h2>All Notifications</h2>
              <button className="close-btn" onClick={() => setOverlayOpen(false)}>×</button>
            </div>
            <div className="overlay-list">
              {notifications.map((note) => (
                <div key={note.id} className="overlay-item">
                  <div className="note-message">{note.message}</div>
                  <div className="note-time">{note.time}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default Notifications;
