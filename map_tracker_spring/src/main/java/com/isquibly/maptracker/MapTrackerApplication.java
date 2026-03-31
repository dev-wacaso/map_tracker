package com.isquibly.maptracker;

import com.isquibly.maptracker.config.AppProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class MapTrackerApplication {

	public static void main(String[] args) {
		SpringApplication.run(MapTrackerApplication.class, args);
	}

}
