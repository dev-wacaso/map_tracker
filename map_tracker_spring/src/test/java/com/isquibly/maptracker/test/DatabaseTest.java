package com.isquibly.maptracker.test;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;

public class DatabaseTest {
    public static void main(String[] args) {
        String url = "jdbc:postgresql://localhost:5432/map_tracker";
        String user = "mapuser";
        String password = "tracker";
        
        try (Connection conn = DriverManager.getConnection(url, user, password)) {
            System.out.println("SUCCESS: Database connection established");
            
            // Check if location_posts table exists
            ResultSet rs = conn.createStatement().executeQuery(
                "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'location_posts')"
            );
            if (rs.next()) {
                boolean exists = rs.getBoolean(1);
                System.out.println("Table location_posts exists: " + exists);
                
                if (exists) {
                    // Count rows in location_posts
                    ResultSet countRs = conn.createStatement().executeQuery(
                        "SELECT COUNT(*) FROM location_posts"
                    );
                    if (countRs.next()) {
                        System.out.println("Rows in location_posts: " + countRs.getInt(1));
                    }
                }
            }
            
        } catch (SQLException e) {
            System.err.println("ERROR: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
