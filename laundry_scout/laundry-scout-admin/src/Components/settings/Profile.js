import React, { useEffect, useState } from "react";
import { supabase } from "../../Supabase/supabaseClient";

function Profile() {
  const [user, setUser] = useState(null);

  useEffect(() => {
    const getUser = async () => {
      const { data, error } = await supabase.auth.getUser();
      if (!error && data?.user) {
        setUser(data.user);
      }
    };
    getUser();
  }, []);

  return (
    <div className="page-container">
      <h2>My Profile</h2>
      {user ? (
        <div>
          <p><strong>Email:</strong> {user.email}</p>
          <p><strong>User ID:</strong> {user.id}</p>
        </div>
      ) : (
        <p>Loading profile...</p>
      )}
    </div>
  );
}

export default Profile;
