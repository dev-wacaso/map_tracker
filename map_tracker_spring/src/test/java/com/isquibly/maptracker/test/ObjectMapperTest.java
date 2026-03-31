package com.isquibly.maptracker.test;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.boot.SpringApplication;
import org.springframework.context.ConfigurableApplicationContext;

public class ObjectMapperTest {
    public static void main(String[] args) {
        try {
            ConfigurableApplicationContext context = SpringApplication.run(com.isquibly.maptracker.MapTrackerApplication.class, args);
            ObjectMapper mapper = context.getBean(ObjectMapper.class);
            System.out.println("SUCCESS: ObjectMapper bean found: " + mapper.getClass().getSimpleName());
            context.close();
        } catch (Exception e) {
            System.err.println("ERROR: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
