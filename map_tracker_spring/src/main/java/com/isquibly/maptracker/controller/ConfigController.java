package com.isquibly.maptracker.controller;

import com.isquibly.maptracker.config.AppProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.sql.DataSource;

@RestController
@RequiredArgsConstructor
public class ConfigController {

    private final AppProperties config;
    
    @Autowired
    private DataSource dataSource;

    @GetMapping("/config")
    public AppProperties getConfig() {
        return config;
    }
    
    @GetMapping("/debug/connection")
    public String getConnectionInfo() {
        try (var connection = dataSource.getConnection()) {
            var metaData = connection.getMetaData();
            return String.format(
                "URL: %s\nUsername: %s\nDatabase: %s\nValid: %s\nDriver: %s\nDriver Version: %s\nDatabase Version: %s",
                metaData.getURL(),
                metaData.getUserName(),
                metaData.getDatabaseProductName(),
                connection.isValid(5),
                metaData.getDriverName(),
                metaData.getDriverVersion(),
                metaData.getDatabaseProductVersion()
            );
        } catch (Exception e) {
            return "Error: " + e.getMessage();
        }
    }
}
