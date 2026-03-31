package com.isquibly.maptracker.controller;

import com.isquibly.maptracker.dto.LocationRequest;
import com.isquibly.maptracker.service.LocationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
public class LocationController {

    private final LocationService locationService;

    @PostMapping("/location")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void postLocation(@Valid @RequestBody LocationRequest request) {
        locationService.handleLocationPost(request);
    }
}
