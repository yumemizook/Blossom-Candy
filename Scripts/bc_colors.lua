-- Blossom Candy Theme - Color Definitions
-- Auto-loaded globally at startup

BCColors = {
  -- Judgment tier colors
  marvelous  = { 1.00, 0.96, 0.82, 1 },  -- warm cream / soft gold  (W1)
  perfect    = { 0.80, 0.72, 0.96, 1 },  -- lavender                (W2)
  great      = { 0.72, 0.94, 0.82, 1 },  -- mint green              (W3)
  good       = { 0.98, 0.82, 0.70, 1 },  -- peach                   (W4)
  bad        = { 0.92, 0.74, 0.78, 1 },  -- dusty rose              (W5)
  miss       = { 0.90, 0.60, 0.62, 1 },  -- muted coral

  -- Semantic aliases
  lavender   = { 0.80, 0.72, 0.96, 1 },  -- same as perfect
  mint       = { 0.72, 0.94, 0.82, 1 },  -- same as great
  peach      = { 0.98, 0.82, 0.70, 1 },  -- same as good

  -- UI chrome
  background = { 0.97, 0.95, 0.98, 1 },
  panel      = { 1.00, 1.00, 1.00, 0.45 },
  text       = { 0.30, 0.28, 0.35, 1 },
  textMuted  = { 0.60, 0.58, 0.65, 1 },
  accent     = { 0.85, 0.72, 0.92, 1 },

  -- Grade colors — one color family per letter tier; +/− variants share the family
  gradeBlossom = { 1.00, 0.92, 0.60, 1 },  -- warm gold     (✦ Blossom — apex)
  gradeSPlus   = { 0.86, 0.76, 0.98, 1 },  -- bright lavender
  gradeS       = { 0.80, 0.72, 0.96, 1 },  -- lavender
  gradeSMinus  = { 0.74, 0.67, 0.90, 1 },  -- muted lavender
  gradeAPlus   = { 0.76, 0.97, 0.86, 1 },  -- bright mint
  gradeA       = { 0.72, 0.94, 0.82, 1 },  -- mint
  gradeAMinus  = { 0.66, 0.88, 0.76, 1 },  -- muted mint
  gradeBPlus   = { 1.00, 0.86, 0.74, 1 },  -- bright peach
  gradeB       = { 0.98, 0.82, 0.70, 1 },  -- peach
  gradeBMinus  = { 0.92, 0.76, 0.64, 1 },  -- muted peach
  gradeCPlus   = { 0.95, 0.78, 0.82, 1 },  -- bright dusty rose
  gradeC       = { 0.92, 0.74, 0.78, 1 },  -- dusty rose
  gradeCMinus  = { 0.86, 0.68, 0.72, 1 },  -- muted dusty rose
  gradeDPlus   = { 0.82, 0.80, 0.84, 1 },  -- light grey
  gradeD       = { 0.75, 0.73, 0.78, 1 },  -- muted grey
  gradeDMinus  = { 0.65, 0.63, 0.68, 1 },  -- dark muted grey
}

-- Helper: get color for a TapNoteScore string value
function BCJudgmentColor(tns)
  if      tns == 'TapNoteScore_W1'   then return BCColors.marvelous
  elseif  tns == 'TapNoteScore_W2'   then return BCColors.perfect
  elseif  tns == 'TapNoteScore_W3'   then return BCColors.great
  elseif  tns == 'TapNoteScore_W4'   then return BCColors.good
  elseif  tns == 'TapNoteScore_W5'   then return BCColors.bad
  else                                     return BCColors.miss end
end

-- Helper: get label for a TapNoteScore string value
function BCJudgmentLabel(tns)
  if      tns == 'TapNoteScore_W1'   then return "Marvelous"
  elseif  tns == 'TapNoteScore_W2'   then return "Perfect"
  elseif  tns == 'TapNoteScore_W3'   then return "Great"
  elseif  tns == 'TapNoteScore_W4'   then return "Good"
  elseif  tns == 'TapNoteScore_W5'   then return "Bad"
  else                                     return "Miss" end
end

-- Grade ladder: { minPct, label, colorKey }
-- Checked top-to-bottom; first match wins.
BCGrades = {
  { 99.9700, "✦ Blossom", "gradeBlossom" },
  { 99.9000, "S+",        "gradeSPlus"   },
  { 99.5000, "S",         "gradeS"       },
  { 99.0000, "S−",        "gradeSMinus"  },
  { 97.5000, "A+",        "gradeAPlus"   },
  { 96.0000, "A",         "gradeA"       },
  { 94.0000, "A−",        "gradeAMinus"  },
  { 92.0000, "B+",        "gradeBPlus"   },
  { 89.0000, "B",         "gradeB"       },
  { 85.0000, "B−",        "gradeBMinus"  },
  { 82.0000, "C+",        "gradeCPlus"   },
  { 78.0000, "C",         "gradeC"       },
  { 72.0000, "C−",        "gradeCMinus"  },
  { 65.0000, "D+",        "gradeDPlus"   },
  { 55.0000, "D",         "gradeD"       },
  {  0.0000, "D−",        "gradeDMinus"  },  -- catch-all, including negatives
}

-- Grade resolver: returns { label, color } for a given BC%
function BCGradeFromPercent(pct)
  for _, tier in ipairs(BCGrades) do
    if pct >= tier[1] then
      return tier[2], BCColors[tier[3]]  -- label, color
    end
  end
  -- Fallback (should not reach here given the 0.0 catch-all)
  return "D−", BCColors.gradeDMinus
end
